# Configuration to be applied inside VM
module GuestConfig
  # Extend Hash to create keys dynamically
  class DynamicHash < Hash
    def self.new
      Hash.new { |hash, key| hash[key] = new }
    end
  end

  @network = DynamicHash.new

  # CentOS/RHEL
  @network[:config_file][:path][:redhat] = '/etc/sysconfig/network-scripts/ifcfg-eth0'
  @network[:config_file][:content][:redhat] = <<~'DOC'
    DEVICE=eth0
    BOOTPROTO=none
    ONBOOT=yes
    PREFIX=%<prefix_length>d
    IPADDR=%<ip>s
    GATEWAY=%<gateway_ip>s
    DNS1=%<dns1>s
    DNS1=%<dns2>s
  DOC
  @network[:apply_cmd][:redhat] = 'sudo systemctl restart network --no-block'

  # Ubuntu
  @network[:config_file][:path][:ubuntu] = '/etc/netplan/01-netcfg.yaml'
  @network[:config_file][:content][:ubuntu] = <<~'DOC'
    network:
      version: 2
      ethernets:
        eth0:
          dhcp4: no
          addresses: [%<ip>s/%<prefix_length>d]
          gateway4: %<gateway_ip>s
          nameservers:
            addresses: [%<dns1>s, %<dns2>s]
  DOC
  @network[:apply_cmd][:ubuntu] = 'sudo netplan apply'

  module_function

  def _get_os_symbol(box)
    pattern_to_os_id_map = {
      ubuntu: 'ubuntu',
      centos: 'redhat',
      rhel: 'redhat'
    }
    key = pattern_to_os_id_map.keys.find { |pattern| box.include?(pattern.to_s) }
    pattern_to_os_id_map[key].to_sym
  end

  def get_templated_network_config(box, template_values)
    os_id = _get_os_symbol(box)
    {
      config_file_path: @network[:config_file][:path][os_id],
      config_file_content: format(@network[:config_file][:content][os_id], template_values),
      apply_cmd: @network[:apply_cmd][os_id]
    }
  end
end
