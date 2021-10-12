# -*- mode: ruby -*-
# vi: set ft=ruby :

START_TIME = Process.clock_gettime(Process::CLOCK_MONOTONIC)

require_relative('./lib/config_file')
require_relative('./lib/guest_config')
require_relative('./lib/hyperv')

# --- Globals ---

CONFIG = ConfigFile.load_file_as_symbolized_hash('config.yml')
TARGET_VMS = ConfigFile.get_enabled_vms(CONFIG)

# --- Helpers ---

def machine_trigger_after_up!(trigger, target_ip, network_spec, box, verbosity)
  # Order matters, reconfigure network on guest first, then change switch.
  template_values = {
    ip: target_ip,
    prefix_length: network_spec[:gateway][:prefix_length],
    gateway_ip: network_spec[:gateway][:ip],
    dns1: network_spec[:dns][:dns1],
    dns2: network_spec[:dns][:dns2]
  }
  network_config = GuestConfig.get_templated_network_config(box, template_values)
  inline_script_template = <<~'DOC'
    echo 'Replacing file: %<config_file_path>s' &&
    printf '%%s' '%<config_file_content>s' > %<config_file_path>s &&
    echo 'Running command: %<apply_cmd>s' &&
    %<apply_cmd>s
  DOC
  trigger.run_remote = { inline: format(inline_script_template, network_config) }
  trigger.ruby do |_, machine|
    HyperV.vm_change_switch(machine.provider_config.vmname, network_spec[:vswitch], verbosity)
  end
end

def print_info?(argv)
  argv.any? { |arg| %w[up halt destroy].include?(arg) } && argv.all? { |arg| !['-h', '--help'].include?(arg) }
end

# --- Run ---

# Print info
if print_info?(ARGV)
  puts "Group: #{CONFIG[:vm_group]}"
  puts 'Target VMs:'
  name_max_length = TARGET_VMS.map { |vm| vm[:name] }.map(&:length).max
  TARGET_VMS.each_with_index do |vm, index|
    printf "%<index>2d) %<name>-#{name_max_length}s | %<ip>s\n", index: index + 1, name: vm[:name], ip: vm[:ip]
  end
end

# Create NAT vSwitch (no 'trigger.before [:up]' in order to run once)
if ARGV.include?('up') && ARGV.all? { |arg| !['-h', '--help'].include?(arg) }
  puts '---'
  puts "Ensure vSwitch \"#{CONFIG[:network][:vswitch]}\" exists..."
  cmd = [
    'PowerShell',
    '-File', './scripts/Create-NAT-vSwitch.ps1',
    '-SwitchName', CONFIG[:network][:vswitch],
    '-IPAddress', CONFIG[:network][:gateway][:ip],
    '-PrefixLength', CONFIG[:network][:gateway][:prefix_length].to_s,
    '-NATNetworkAddressPrefix', CONFIG[:network][:nat][:address_prefix],
    '-NATName', CONFIG[:network][:nat][:name]
  ]
  if (CONFIG[:settings][:verbosity]).positive?
    printf "Running command: %<command>s\n", command: cmd.map { |arg| arg.include?(' ') ? %("#{arg}") : arg }.join(' ')
  end
  system(*cmd, exception: true) # raise error on non 0 exit code
  puts '---'
end

Vagrant.configure(2) do |config|
  config.vm.box = CONFIG[:box]
  # --- Set up SSH ---
  config.ssh.insert_key = false
  public_key_path = File.expand_path(CONFIG[:ssh][:public_key_path])
  public_key = File.read(public_key_path).strip
  inline_script = <<~DOC
    echo 'Adding SSH public key to authorized keys...' &&
    mkdir -p ~/.ssh &&
    chmod 700 ~/.ssh &&
    echo '#{public_key}' >> ~/.ssh/authorized_keys &&
    chmod 600 ~/.ssh/authorized_keys
  DOC
  config.vm.provision :shell, inline: inline_script, privileged: false
  TARGET_VMS.each do |vm_spec|
    config.vm.define vm_spec[:name] do |machine|
      vm_full_name = "#{CONFIG[:vm_group]}/#{vm_spec[:name]}"
      machine.vm.hostname = vm_spec[:hostname]
      # use "Default Switch" only when creating VM
      machine.vm.network 'public_network', bridge: 'Default Switch' unless HyperV.vm_exists?(vm_full_name)
      machine.vm.provider 'hyperv' do |provider|
        provider.cpus = vm_spec[:cpus]
        provider.memory = vm_spec[:memory]
        provider.vmname = vm_full_name
        provider.linked_clone = true
        provider.maxmemory = vm_spec[:memory]
        # Hyper-V assigns MAC address for each adapter dynamically
      end
      machine.trigger.after :up do |trigger|
        trigger.name = 'Set static IP inside VM then change switch'
        machine_trigger_after_up!(trigger, vm_spec[:ip], CONFIG[:network], config.vm.box, CONFIG[:settings][:verbosity])
      end
    end
  end
end

at_exit do
  if print_info?(ARGV)
    # Run time info
    end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    elapsed_time = end_time - START_TIME
    puts '---'
    puts "Ended at: #{Time.now.strftime('%H:%M')}"
    format = '%Ss'
    format.prepend('%Mm ') if elapsed_time >= 60
    format.prepend('%Hm ') if elapsed_time >= 3600
    puts "Elapsed time: #{Time.at(elapsed_time).utc.strftime(format)}"
  end
end
