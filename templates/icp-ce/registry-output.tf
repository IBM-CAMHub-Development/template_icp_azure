module "gather_output" {
    source 						= "git::https://github.com/IBM-CAMHub-Open/template_icp_modules.git?ref=2.3//public_cloud_output"
	cluster_CA_domain 			= "${element(azurerm_public_ip.master_pip.*.fqdn, 0)}"
	icp_master 					= "${azurerm_public_ip.master_pip.*.ip_address}"
	ssh_user 					= "${var.admin_username}"
	ssh_key_base64 				= "${base64encode(tls_private_key.installkey.private_key_pem)}"
	bastion_host 				= "${element(concat(azurerm_public_ip.bootnode_pip.*.ip_address, azurerm_public_ip.master_pip.*.ip_address), 0)}"
	bastion_user    			= "${var.admin_username}"
    bastion_private_key_base64 	= "${base64encode(tls_private_key.installkey.private_key_pem)}"
}

output "registry_ca_cert"{
  value = "${module.gather_output.registry_ca_cert}"
} 

output "icp_install_dir"{
  value = "${module.gather_output.icp_install_dir}"
} 

output "registry_config_do_name"{
	value = "${var.instance_name}${random_id.clusterid.hex}RegistryConfig"
}
