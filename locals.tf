locals {
    private_subnet_types = [
        "private_with_internet", # egress with public nat gateway.
        "private_only", # no internet access, only multi acc vpc access to internal private networks.
        "private_tgw_attachment", # used for transit gateway attachment with vpcs.
    ]
    public_subnet_types = [
        "public",        
    ]
}