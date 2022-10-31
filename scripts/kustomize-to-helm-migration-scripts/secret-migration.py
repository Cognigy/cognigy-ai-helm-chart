#!/bin/env python3

import itertools
import pathlib
import subprocess
import yaml
import base64
import argparse

secrets_list_helm_regular = [
    "cognigy-amazon-credentials",
    "cognigy-live-agent-credentials",
    "cognigy-management-ui-creds",
    "cognigy-smtp",
    "cognigy-traefik"
]

secrets_list_helm_resource_keep = [
    "cognigy-facebook",
    "cognigy-jwt",
    "cognigy-insights-jwt",
    "cognigy-odata",
    "cognigy-rabbitmq",
    "cognigy-rce-credentials",
    "redis-password",
    "redis-persistent.password"
]

secrets_list_helm_pre_installation = [
    "cognigy-service-ai",
    "cognigy-service-alexa-management",
    "cognigy-service-analytics-collector-provider",
    "cognigy-service-analytics-conversation-collector-provider",
    "cognigy-service-api",
    "cognigy-service-custom-modules",
    "cognigy-service-function-scheduler",
    "cognigy-service-handover",
    "cognigy-service-journeys",
    "cognigy-service-logs",
    "cognigy-service-nlp",
    "cognigy-service-profiles",
    "cognigy-service-resources",
    "cognigy-service-runtime-file-manager",
    "cognigy-service-security",
    "cognigy-service-task-manager",
    "cognigy-service-trainer"
]

insights_secrets_old = [
    "cognigy-service-analytics-collector-provider",
    "cognigy-service-analytics-conversation-collector-provider"
]

insights_secrets_new = [
    "cognigy-service-analytics-collector",
    "cognigy-service-analytics-conversation"
]

def create_output_directory(current_dir):
    subprocess.run(f"mkdir -p {current_dir}/migration-secrets", shell=True)

def modify_secrets(current_dir, ns):
    dict_annotation_helm_regular = {
        "annotations" : {
            "meta.helm.sh/release-name": "cognigy-ai",
            "meta.helm.sh/release-namespace": ns
        },
        "labels" : {
            "app.kubernetes.io/managed-by": "Helm"
        },
        "namespace" : ns
    }
    dict_annotation_helm_resource_keep = {
        "annotations": {
            "helm.sh/resource-policy": "keep", 
            "meta.helm.sh/release-name": "cognigy-ai", 
            "meta.helm.sh/release-namespace": ns
        },
        "labels": {
            "app.kubernetes.io/managed-by": "Helm"
        },
        "namespace": ns
    }
    dict_annotation_helm_pre_installation = { 
        "annotations": {
            "helm.sh/resource-policy": "keep",
            "helm.sh/hook": "pre-install",
            "helm.sh/hook-weight": "-4"
        },
        "namespace": ns
    }

    for i in secrets_list_helm_regular:
        secret_file_helm_regular=open(f"{current_dir}/secrets/{i}.yaml")
        yaml_data_helm_regular=yaml.load(secret_file_helm_regular, Loader=yaml.SafeLoader)
        yaml_data_helm_regular["metadata"].update(dict_annotation_helm_regular)

        with open(f"{current_dir}/migration-secrets/{i}.yaml", "w") as file: 
            yaml.dump(yaml_data_helm_regular, file)
        secret_file_helm_regular.close()
    
    for j in secrets_list_helm_resource_keep:
        secret_file_helm_resource_keep=open(f"{current_dir}/secrets/{j}.yaml")
        yaml_data_helm_resource_keep=yaml.load(secret_file_helm_resource_keep, Loader=yaml.SafeLoader)
        yaml_data_helm_resource_keep["metadata"].update(dict_annotation_helm_resource_keep)

        with open(f"{current_dir}/migration-secrets/{j}.yaml", "w") as file: 
            yaml.dump(yaml_data_helm_resource_keep, file)
        secret_file_helm_resource_keep.close()
    
    for k in secrets_list_helm_pre_installation:
        secret_file_helm_pre_installation=open(f"{current_dir}/secrets/{k}.yaml")
        yaml_data_helm_pre_installation=yaml.load(secret_file_helm_pre_installation, Loader=yaml.SafeLoader)
        yaml_data_helm_pre_installation["metadata"].update(dict_annotation_helm_pre_installation)

        with open(f"{current_dir}/migration-secrets/{k}.yaml", "w") as file: 
            yaml.dump(yaml_data_helm_pre_installation, file)
        secret_file_helm_pre_installation.close()

def modify_insights_secrets(current_dir):
    for (i,j) in itertools.zip_longest(insights_secrets_old, insights_secrets_new):
        secret_file=open(f"{current_dir}/migration-secrets/{i}.yaml")
        yaml_data=yaml.load(secret_file, Loader=yaml.SafeLoader)
        old_database_name=i.replace("cognigy-", "")
        new_database_name=j.replace("cognigy-", "")
        old_secret_decoded=base64.b64decode(yaml_data["data"]["connection-string"])
        new_secret_decoded=(old_secret_decoded.decode("utf-8")).replace(old_database_name, new_database_name)
        new_secret_encoded=base64.b64encode(new_secret_decoded.encode())
        secret_converted_from_byte_to_string=(new_secret_encoded.decode("utf-8"))
        yaml_data["data"]["connection-string"]=secret_converted_from_byte_to_string
        yaml_data["metadata"]["name"]=j

        with open(f"{current_dir}/migration-secrets/{j}.yaml", "w") as file: 
            yaml.dump(yaml_data, file)
        secret_file.close()

        # Remove the old insights secrets file
        old_secret_file=pathlib.Path(f"{current_dir}/migration-secrets/{i}.yaml")
        if old_secret_file.exists():
            old_secret_file.unlink()
        else: 
            print("old pattern insights secret file does not exist")

if __name__=='__main__':
    parser = argparse.ArgumentParser(description='Secret migration for kustomize-to-helm migration')
    parser.add_argument("-ns", "--namespace",
                        help = "Provide the target namespace to deploy cognigy-ai. Default target namespace is cognigy-ai",
                        default = "cognigy-ai",
                        type = str)
    parser.add_argument("-cognigyApps", "--cognigyApps",
                        action = 'store_true',
                        help = "Include this argument if Cognigy Apps is enabled",
                        default = False)
    args = parser.parse_args()

    ns = args.namespace
    cognigy_apps = args.cognigyApps

    current_directory = subprocess.check_output('pwd', shell=True)
    current_directory_decoded = (current_directory.decode("utf-8")).rstrip('\n')

    if cognigy_apps:
        secrets_list_helm_pre_installation.append("cognigy-service-app-session-manager")

    create_output_directory(current_directory_decoded)
    modify_secrets(current_directory_decoded, ns)
    modify_insights_secrets(current_directory_decoded)