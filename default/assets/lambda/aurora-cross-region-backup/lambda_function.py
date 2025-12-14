import json
import boto3
import os
from datetime import datetime, timedelta
import logging
from typing import Dict, List, Any

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    try:
        # Environment variables
        source_region = os.environ['SOURCE_REGION']
        destination_region = os.environ['DESTINATION_REGION']
        cluster_identifier = os.environ['CLUSTER_IDENTIFIER']
        global_cluster_id = os.environ.get('GLOBAL_CLUSTER_ID')
        backup_type = os.environ.get('BACKUP_TYPE', 'snapshot')
        retention_days = int(os.environ.get('RETENTION_DAYS', 30))
        target_kms_key_id = os.environ.get('TARGET_KMS_KEY_ID')
        
        logger.info(f'Starting Aurora cross-region backup: {backup_type}')
        
        # Send start notification
        try:
            sns = boto3.client('sns')
            sns.publish(
                TopicArn=os.environ.get('OPERATIONAL_TOPIC_ARN', os.environ.get('ERROR_TOPIC_ARN')),
                Subject=f'Aurora Backup Started - {cluster_identifier}',
                Message=f'Aurora cross-region backup started:\n- Type: {backup_type}\n- Cluster: {cluster_identifier}\n- Source Region: {source_region}\n- Destination Region: {destination_region}\n- Retention: {retention_days} days'
            )
        except Exception as notify_error:
            logger.warning(f'Failed to send start notification: {str(notify_error)}')
        
        if backup_type == 'global_database':
            return handle_global_database_backup(
                source_region, destination_region, cluster_identifier, global_cluster_id, target_kms_key_id
            )
        elif backup_type == 'snapshot':
            return handle_snapshot_backup(
                source_region, destination_region, cluster_identifier, retention_days, target_kms_key_id
            )
        else:
            raise ValueError(f'Unsupported backup type: {backup_type}')
            
    except Exception as e:
        logger.error(f'Error in cross-region backup: {str(e)}')
        # Send to SNS for alerting
        sns = boto3.client('sns')
        try:
            sns.publish(
                TopicArn=os.environ.get('ERROR_TOPIC_ARN'),
                Subject=f'Aurora Backup Lambda Error - {cluster_identifier}',
                Message=f'Error in Aurora cross-region backup: {str(e)}'
            )
        except:
            pass
        raise e

def handle_global_database_backup(source_region: str, destination_region: str, 
                                 cluster_identifier: str, global_cluster_id: str, target_kms_key_id: str = None) -> Dict[str, Any]:
    rds = boto3.client('rds', region_name=source_region)
    
    try:
        # Check if global database already exists
        global_clusters = rds.describe_global_clusters()
        existing_global = None
        
        for cluster in global_clusters['GlobalClusters']:
            if cluster['GlobalClusterIdentifier'] == global_cluster_id:
                existing_global = cluster
                break
        
        if existing_global:
            logger.info(f'Global database {global_cluster_id} already exists')
            # Check if secondary region is already added
            secondary_exists = any(
                member['DBClusterArn'].find(destination_region) != -1 
                for member in existing_global['GlobalClusterMembers']
            )
            
            if not secondary_exists:
                logger.info(f'Adding secondary region {destination_region}')
                # Create secondary cluster in destination region
                dest_rds = boto3.client('rds', region_name=destination_region)
                dest_rds.create_db_cluster(
                    DBClusterIdentifier=f'{cluster_identifier}-secondary',
                    Engine='aurora-postgresql',
                    GlobalClusterIdentifier=global_cluster_id,
                    BackupRetentionPeriod=7,
                    StorageEncrypted=True
                )
                
            return {
                'statusCode': 200,
                'body': json.dumps({
                    'message': 'Global database backup configured',
                    'globalClusterId': global_cluster_id,
                    'secondaryRegion': destination_region
                })
            }
        else:
            # Create new global database
            logger.info(f'Creating global database {global_cluster_id}')
            rds.create_global_cluster(
                GlobalClusterIdentifier=global_cluster_id,
                SourceDBClusterIdentifier=cluster_identifier,
                Engine='aurora-postgresql',
                StorageEncrypted=True
            )
            
            return {
                'statusCode': 200,
                'body': json.dumps({
                    'message': 'Global database created successfully',
                    'globalClusterId': global_cluster_id
                })
            }
            
    except Exception as e:
        logger.error(f'Error in global database backup: {str(e)}')
        raise e

def handle_snapshot_backup(source_region: str, destination_region: str, 
                          cluster_identifier: str, retention_days: int, target_kms_key_id: str = None) -> Dict[str, Any]:
    source_rds = boto3.client('rds', region_name=source_region)
    dest_rds = boto3.client('rds', region_name=destination_region)
    sts_client = boto3.client('sts')
    
    # Create manual snapshot
    snapshot_id = f'{cluster_identifier}-backup-{datetime.now().strftime("%Y%m%d-%H%M%S")}'
    
    logger.info(f'Creating manual snapshot: {snapshot_id}')
    source_rds.create_db_cluster_snapshot(
        DBClusterSnapshotIdentifier=snapshot_id,
        DBClusterIdentifier=cluster_identifier,
        Tags=[
            {'Key': 'Purpose', 'Value': 'CrossRegionBackup'},
            {'Key': 'BackupType', 'Value': 'Manual'},
            {'Key': 'CreatedBy', 'Value': 'aurora-cross-region-backup-lambda'},
            {'Key': 'RetentionDays', 'Value': str(retention_days)}
        ]
    )
    
    # Wait for snapshot to be available before copying
    logger.info(f'Waiting for snapshot {snapshot_id} to be available...')
    
    # First check if snapshot is already available to avoid unnecessary waiting
    try:
        snapshot_info = source_rds.describe_db_cluster_snapshots(
            DBClusterSnapshotIdentifier=snapshot_id
        )
        current_status = snapshot_info['DBClusterSnapshots'][0]['Status']
        logger.info(f'Current snapshot status: {current_status}')
        
        if current_status == 'available':
            logger.info(f'Snapshot {snapshot_id} is already available')
        else:
            # Use waiter only if snapshot is not yet available
            waiter = source_rds.get_waiter('db_cluster_snapshot_available')
            waiter.wait(
                DBClusterSnapshotIdentifier=snapshot_id,
                WaiterConfig={
                    'Delay': 30,  # Check every 30 seconds
                    'MaxAttempts': 25  # Wait up to 12.5 minutes (30 * 25 = 750 seconds)
                }
            )
            logger.info(f'Snapshot {snapshot_id} is now available')
    except Exception as e:
        logger.error(f'Error waiting for snapshot to be available: {str(e)}')
        raise e
    
    # Get snapshot ARN for cross-region copy
    snapshot_arn = f'arn:aws:rds:{source_region}:{sts_client.get_caller_identity()["Account"]}:cluster-snapshot:{snapshot_id}'
    
    target_snapshot_id = f'{cluster_identifier}-cross-region-{datetime.now().strftime("%Y%m%d-%H%M%S")}'
    
    logger.info(f'Copying snapshot to {destination_region}: {target_snapshot_id}')
    
    # Prepare copy parameters
    copy_params = {
        'SourceDBClusterSnapshotIdentifier': snapshot_arn,
        'TargetDBClusterSnapshotIdentifier': target_snapshot_id,
        'CopyTags': True,
        'Tags': [
            {'Key': 'Purpose', 'Value': 'CrossRegionBackup'},
            {'Key': 'SourceRegion', 'Value': source_region},
            {'Key': 'BackupType', 'Value': 'CrossRegionCopy'},
            {'Key': 'CreatedBy', 'Value': 'aurora-cross-region-backup-lambda'},
            {'Key': 'RetentionDays', 'Value': str(retention_days)}
        ]
    }
    
    # Add KMS key if specified (required for encrypted snapshots)
    if target_kms_key_id:
        copy_params['KmsKeyId'] = target_kms_key_id
        logger.info(f'Using KMS key: {target_kms_key_id}')
    
    dest_rds.copy_db_cluster_snapshot(**copy_params)
    
    # Clean up old snapshots
    cleanup_old_snapshots(source_rds, cluster_identifier, retention_days, 'source')
    cleanup_old_snapshots(dest_rds, cluster_identifier, retention_days, 'destination')
    
    # Send completion notification
    try:
        sns = boto3.client('sns')
        sns.publish(
            TopicArn=os.environ.get('OPERATIONAL_TOPIC_ARN', os.environ.get('ERROR_TOPIC_ARN')),
            Subject=f'Aurora Backup Completed - {cluster_identifier}',
            Message=f'Aurora cross-region backup completed successfully:\n- Source Snapshot: {snapshot_id}\n- Target Snapshot: {target_snapshot_id}\n- Destination Region: {destination_region}\n- Total Duration: Completed at {datetime.now().strftime("%Y-%m-%d %H:%M:%S UTC")}'
        )
    except Exception as notify_error:
        logger.warning(f'Failed to send completion notification: {str(notify_error)}')
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': 'Cross-region snapshot backup completed',
            'sourceSnapshot': snapshot_id,
            'targetSnapshot': target_snapshot_id,
            'destinationRegion': destination_region
        })
    }

def cleanup_old_snapshots(rds_client, cluster_identifier: str, retention_days: int, region_type: str):
    try:
        logger.info(f'Cleaning up old snapshots in {region_type} region')
        
        # Get manual snapshots
        snapshots = rds_client.describe_db_cluster_snapshots(
            DBClusterIdentifier=cluster_identifier,
            SnapshotType='manual',
            MaxRecords=100
        )
        
        cutoff_date = datetime.now() - timedelta(days=retention_days)
        deleted_count = 0
        
        for snapshot in snapshots['DBClusterSnapshots']:
            if snapshot['SnapshotCreateTime'].replace(tzinfo=None) < cutoff_date:
                # Check if this is a backup snapshot based on naming convention or tags
                snapshot_id = snapshot['DBClusterSnapshotIdentifier']
                if ('backup-' in snapshot_id or 'cross-region-' in snapshot_id):
                    try:
                        logger.info(f'Deleting old snapshot: {snapshot_id}')
                        rds_client.delete_db_cluster_snapshot(
                            DBClusterSnapshotIdentifier=snapshot_id
                        )
                        deleted_count += 1
                    except Exception as e:
                        logger.warning(f'Failed to delete snapshot {snapshot_id}: {str(e)}')
        
        logger.info(f'Deleted {deleted_count} old snapshots in {region_type} region')
        
    except Exception as e:
        logger.error(f'Error cleaning up snapshots in {region_type} region: {str(e)}')
