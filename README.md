# PoC for AD DR

Terraform scripts in `tf` folder deploy AD domain controller in Azure and configure a backup job using Recovery Services Vault and isolated environment for restoring DC from backup.


Script `restore-dc.ps1` then restores the latest backup from RSV to isolated network previously deployed by Terraform.

