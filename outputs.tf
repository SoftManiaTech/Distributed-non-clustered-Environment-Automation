output "splunk_instances" {
  description = "Public or Elastic IP with credentials for all Splunk components"

  value = {
    "Search Head" = {
      public_ip = aws_eip.splunk_eips[0].public_ip != "" ? aws_eip.splunk_eips[0].public_ip : aws_instance.Splunk_sh_idx_hf[0].public_ip
      username  = "admin"
      password  = "admin123"
    },
    "Indexer" = {
      public_ip = aws_eip.splunk_eips[1].public_ip != "" ? aws_eip.splunk_eips[1].public_ip : aws_instance.Splunk_sh_idx_hf[1].public_ip
      username  = "admin"
      password  = "admin123"
    },
    "Heavy Forwarder" = {
      public_ip = aws_eip.splunk_eips[2].public_ip != "" ? aws_eip.splunk_eips[2].public_ip : aws_instance.Splunk_sh_idx_hf[2].public_ip
      username  = "admin"
      password  = "admin123"
    },
    "Universal Forwarder" = {
      public_ip = aws_eip.uf_eip.public_ip != "" ? aws_eip.uf_eip.public_ip : aws_instance.Splunk_uf.public_ip
      username  = "admin"
      password  = "admin123"
    }
  }
}
