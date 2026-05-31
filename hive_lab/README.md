# Infraestructura AWS EMR con Terraform

Este directorio contiene la configuración de Terraform para desplegar un clúster **AWS EMR** con **Hadoop, Hive, Tez, Hue y Pig**, junto con la VPC, subred, Internet Gateway y security group necesarios.

## Recursos que crea

| Recurso              | Descripción                                                   |
| -------------------- | ------------------------------------------------------------- |
| **VPC**              | `10.0.0.0/16` con DNS hostnames habilitado (requisito de EMR) |
| **Subnet**           | `10.0.1.0/24` pública en `us-east-1a`                         |
| **Internet Gateway** | Para salida a internet                                        |
| **Route Table**      | Ruta `0.0.0.0/0` → IGW                                        |
| **Security Group**   | Puerto 22 abierto a `0.0.0.0/0` (SSH al nodo maestro)         |
| **EMR Cluster**      | `emr-7.13.0` con 1 master + 3 core nodes (`r8g.xlarge`)       |

> **IMPORTANTE:** El cluster usa los roles por defecto `EMR_DefaultRole` y `EMR_EC2_DefaultRole`. Deben existir en tu cuenta de AWS antes de desplegar.

## Prerrequisitos

1. **AWS CLI** configurado con credenciales (`aws configure`)
2. **Terraform** v1.5+
3. **Key pair EC2** llamado `deitakey` en la región `us-east-1` (o cambia `key_name` en `main.tf`)
4. Roles IAM creados por AWS:
   - `EMR_DefaultRole` (service role)
   - `EMR_EC2_DefaultRole` (instance profile)

   Si no existen, créalos con:

   ```console
   aws emr create-default-roles
   ```

## Desplegar

```console
# Inicializar Terraform
terraform init

# Ver el plan
terraform plan

# Aplicar
terraform apply -auto-approve
```

Script:

```console
chmod +x deploy.sh
./deploy.sh
```

## Outputs

Al terminar, Terraform muestra el **DNS público** del nodo maestro:

```
emr_master_public_dns = "ec2-xx-xx-xx-xx.compute-1.amazonaws.com"
```

## Conectarse por SSH

```console
ssh -i ~/tu-key.pem hadoop@<emr_master_public_dns>
```

## Destruir

```console
terraform destroy -auto-approve
```

O:

```console
./destroy.sh
```

## Notas

- El security group expone SSH a `0.0.0.0/0`. En producción, restringe el CIDR a tu IP.
- Los costos del cluster corren mientras esté vivo. Destruirlo cuando no se use.
- `keep_job_flow_alive_when_no_steps = true` mantiene el cluster encendido después de los steps.
- Los logs se almacenan en `s3://hdfs-emr-bigdeita/logs/`.
