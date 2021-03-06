#Virtual Network
resource "azurerm_virtual_network" "icp_vnet" {
  name                = "${var.virtual_network_name}"
  location            = "${var.location}"
  #address_space       = ["${var.subnet_prefix}", "${var.cluster_ip_range}", "${var.network_cidr}"]
  address_space       = ["${var.virtual_network_cidr}"]
  resource_group_name = "${azurerm_resource_group.icp.name}"
}

#Route Table
resource "azurerm_route_table" "routetb" {
  name                = "${var.route_table_name}"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.icp.name}"
}

#Subnetwork
resource "azurerm_subnet" "subnet" {
  name                 = "${var.subnet_name}"
  virtual_network_name = "${azurerm_virtual_network.icp_vnet.name}"
  resource_group_name  = "${azurerm_resource_group.icp.name}"
  address_prefix       = "${var.subnet_prefix}"
}

resource "azurerm_subnet_route_table_association" "subnet" {
  subnet_id      = "${azurerm_subnet.subnet.id}"
  route_table_id = "${azurerm_route_table.routetb.id}"
}


resource "azurerm_subnet" "container_subnet" {
  name                 = "icp-container-network"
  virtual_network_name = "${azurerm_virtual_network.icp_vnet.name}"
  resource_group_name  = "${azurerm_resource_group.icp.name}"
  address_prefix       = "${var.network_cidr}"
}

resource "azurerm_subnet_route_table_association" "container_subnet" {
  subnet_id      = "${azurerm_subnet.container_subnet.id}"
  route_table_id = "${azurerm_route_table.routetb.id}"
}

#Public IP
resource "azurerm_public_ip" "bootnode_pip" {
  count                        = "${var.boot["nodes"]}"
  name                         = "${var.boot["name"]}-pip-${count.index}"
  location                     = "${var.location}"
  resource_group_name          = "${azurerm_resource_group.icp.name}"
  allocation_method = "Static"
  sku                          = "Standard"
  domain_name_label            = "bootnode-${random_id.clusterid.hex}"
}

resource "azurerm_public_ip" "master_pip" {
  count                        = "${var.master["nodes"]}"
  name                         = "${var.master["name"]}-pip-${count.index}"
  location                     = "${var.location}"
  resource_group_name          = "${azurerm_resource_group.icp.name}"
  allocation_method = "Static"
  sku                          = "Standard"
  domain_name_label            = "${var.cluster_name}-${random_id.clusterid.hex}"
}

resource "azurerm_public_ip" "proxy_pip" {
  count                        = "${var.proxy["nodes"]}"
  name                         = "${var.proxy["name"]}-pip-${count.index}"
  location                     = "${var.location}"
  resource_group_name          = "${azurerm_resource_group.icp.name}"
  allocation_method = "Static"
  sku                          = "Standard"
  domain_name_label            = "${var.cluster_name}-${random_id.clusterid.hex}-ingress"
}

#Network Interface
resource "azurerm_network_interface" "boot_nic" {
  count               = "${var.boot["nodes"]}"
  name                = "${var.boot["name"]}-nic-${count.index}"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.icp.name}"
  network_security_group_id = "${azurerm_network_security_group.boot_sg.id}"
  enable_ip_forwarding      = "true"

  ip_configuration {
    name                          = "BootIPAddress"
    subnet_id                     = "${azurerm_subnet.subnet.id}"
    public_ip_address_id          = "${azurerm_public_ip.bootnode_pip.id}"
    private_ip_address_allocation = "Dynamic"
  }
}
resource "azurerm_network_interface" "master_nic" {
  count               = "${var.master["nodes"]}"
  name                = "${var.master["name"]}-nic-${count.index}"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.icp.name}"
  network_security_group_id = "${azurerm_network_security_group.master_sg.id}"
  enable_ip_forwarding      = "true"

  ip_configuration {
    name                          = "${var.master["name"]}-ipcfg-${count.index}"
    subnet_id                     = "${azurerm_subnet.subnet.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${element(azurerm_public_ip.master_pip.*.id, count.index)}"
  }
}

resource "azurerm_network_interface" "proxy_nic" {
  count               = "${var.proxy["nodes"]}"
  name                = "${var.proxy["name"]}-nic-${count.index}"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.icp.name}"
  network_security_group_id = "${azurerm_network_security_group.proxy_sg.id}"
  enable_ip_forwarding      = "true"

  ip_configuration {
    name                          = "${var.proxy["name"]}-ipcfg-${count.index}"
    subnet_id                     = "${azurerm_subnet.subnet.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${element(azurerm_public_ip.proxy_pip.*.id, count.index)}"
  }
}

resource "azurerm_network_interface" "management_nic" {
  count               = "${var.management["nodes"]}"
  name                = "${var.management["name"]}-nic-${count.index}"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.icp.name}"
  network_security_group_id = "${azurerm_network_security_group.worker_sg.id}"
  enable_ip_forwarding      = "true"

  ip_configuration {
    name                          = "${var.management["name"]}-ipcfg-${count.index}"
    subnet_id                     = "${azurerm_subnet.subnet.id}"
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "worker_nic" {
  count               = "${var.worker["nodes"]}"
  name                = "${var.worker["name"]}-nic-${count.index}"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.icp.name}"
  network_security_group_id = "${azurerm_network_security_group.worker_sg.id}"
  enable_ip_forwarding      = "true"

  ip_configuration {
    name                          = "${var.worker["name"]}-ipcfg-${count.index}"
    subnet_id                     = "${azurerm_subnet.subnet.id}"
    private_ip_address_allocation = "Dynamic"
  }
}
