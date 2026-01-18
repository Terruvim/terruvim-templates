import { terruvimDeploy } from 'terruvim-core-test';
import * as pulumi from '@pulumi/pulumi';

const deployment = terruvimDeploy(__dirname + '/envs');