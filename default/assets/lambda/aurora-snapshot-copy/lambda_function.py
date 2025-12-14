import json
import boto3
import os
from datetime import datetime, timedelta
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    try:
        # Environment variables
        source_region = os.environ['SOURCE_REGION']
        destination_region = os.environ['DESTINATION_REGION']
        cluster_identifier = os.environ['CLUSTER_IDENTIFIER']
        retention_days = int(os.environ.get('RETENTION_DAYS', 7))
        target_kms_key_id = os.environ.get('TARGET_KMS_KEY_ID')
        
        # Initialize RDS clients
        source_rds = boto3.client('rds', region_name=source_region)
        dest_rds = boto3.client('rds', region_name=destination_region)
        
        logger.info(f'Starting snapshot copy from {source_region} to {destination_region}')
        
        # Send start notification
        try:
            sns = boto3.client('sns')
            sns.publish(
                TopicArn=os.environ.get('OPERATIONAL_TOPIC_ARN', os.environ.get('ERROR_TOPIC_ARN')),
                Subject=f'Aurora Snapshot Copy Started - {cluster_identifier}',
                Message=f'Aurora snapshot copy started:\n- Cluster: {cluster_identifier}\n- Source Region: {source_region}\n- Destination Region: {destination_region}\n- Retention: {retention_days} days'
            )
        except Exception as notify_error:
            logger.warning(f'Failed to send start notification: {str(notify_error)}')
        
        # Get the latest automatic snapshot
        snapshots = source_rds.describe_db_cluster_snapshots(
            DBClusterIdentifier=cluster_identifier,
            SnapshotType='automated',
            MaxRecords=20
        )
        
        if not snapshots['DBClusterSnapshots']:
            logger.warning('No automated snapshots found')
            return {'statusCode': 200, 'body': 'No snapshots to copy'}
        
        # Sort by creation time and get the latest
        latest_snapshot = sorted(
            snapshots['DBClusterSnapshots'],
            key=lambda x: x['SnapshotCreateTime'],
            reverse=True
        )[0]
        
        source_snapshot_arn = latest_snapshot['DBClusterSnapshotArn']
        target_snapshot_id = f"{cluster_identifier}-cross-region-{datetime.now().strftime('%Y%m%d-%H%M%S')}"
        
        logger.info(f'Copying snapshot {source_snapshot_arn} to {target_snapshot_id}')
        
        # Prepare copy parameters
        copy_params = {
            'SourceDBClusterSnapshotIdentifier': source_snapshot_arn,
            'TargetDBClusterSnapshotIdentifier': target_snapshot_id,
            'CopyTags': True,
            'Tags': [
                {'Key': 'Purpose', 'Value': 'CrossRegionBackup'},
                {'Key': 'SourceRegion', 'Value': source_region},
                {'Key': 'CreatedBy', 'Value': 'aurora-snapshot-copy-lambda'},
                {'Key': 'RetentionDays', 'Value': str(retention_days)}
            ]
        }
        
        # Add KMS key if specified (required for encrypted snapshots)
        if target_kms_key_id:
            copy_params['KmsKeyId'] = target_kms_key_id
            logger.info(f'Using KMS key: {target_kms_key_id}')
        
        # Copy snapshot to destination region
        copy_response = dest_rds.copy_db_cluster_snapshot(**copy_params)
        
        logger.info(f'Snapshot copy initiated: {copy_response["DBClusterSnapshot"]["DBClusterSnapshotIdentifier"]}')
        
        # Clean up old cross-region snapshots
        cleanup_old_snapshots(dest_rds, cluster_identifier, retention_days)
        
        # Send completion notification
        try:
            sns = boto3.client('sns')
            sns.publish(
                TopicArn=os.environ.get('OPERATIONAL_TOPIC_ARN', os.environ.get('ERROR_TOPIC_ARN')),
                Subject=f'Aurora Snapshot Copy Completed - {cluster_identifier}',
                Message=f'Aurora snapshot copy completed successfully:\n- Source Snapshot: {source_snapshot_arn}\n- Target Snapshot: {target_snapshot_id}\n- Destination Region: {destination_region}\n- Completed at: {datetime.now().strftime("%Y-%m-%d %H:%M:%S UTC")}'
            )
        except Exception as notify_error:
            logger.warning(f'Failed to send completion notification: {str(notify_error)}')
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Snapshot copy completed successfully',
                'sourceSnapshot': source_snapshot_arn,
                'targetSnapshot': target_snapshot_id
            })
        }
        
    except Exception as e:
        logger.error(f'Error in snapshot copy: {str(e)}')
        raise e

def cleanup_old_snapshots(rds_client, cluster_identifier, retention_days):
    try:
        # Get all manual snapshots for this cluster
        snapshots = rds_client.describe_db_cluster_snapshots(
            DBClusterIdentifier=cluster_identifier,
            SnapshotType='manual',
            MaxRecords=100
        )
        
        cutoff_date = datetime.now() - timedelta(days=retention_days)
        
        for snapshot in snapshots['DBClusterSnapshots']:
            if (snapshot['SnapshotCreateTime'].replace(tzinfo=None) < cutoff_date and
                'cross-region' in snapshot['DBClusterSnapshotIdentifier']):
                
                logger.info(f'Deleting old snapshot: {snapshot["DBClusterSnapshotIdentifier"]}')
                rds_client.delete_db_cluster_snapshot(
                    DBClusterSnapshotIdentifier=snapshot['DBClusterSnapshotIdentifier']
                )
                
    except Exception as e:
        logger.error(f'Error cleaning up old snapshots: {str(e)}')
