import { terruvimDeploy } from 'node_modules/terruvim';
import * as pulumi from '@pulumi/pulumi';

const deployment = terruvimDeploy(__dirname + '/envs');