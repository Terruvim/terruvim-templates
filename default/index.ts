import { terruvimDeploy } from 'terruvim';
import * as pulumi from '@pulumi/pulumi';

const deployment = terruvimDeploy(__dirname + '/envs');