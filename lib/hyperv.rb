require 'open3'

# Hyper-V-specific helpers
module HyperV
  PS_CMD_STOP_ON_ERROR_TEMPLATE = %(PowerShell -Command "& { $ErrorActionPreference = 'Stop'; %<command>s }").freeze

  module_function

  def vm_exists?(vm_name)
    ps_cmd = "'#{vm_name}' -in (Get-VM | Select-Object -ExpandProperty Name)"
    cmd = format(PS_CMD_STOP_ON_ERROR_TEMPLATE, command: ps_cmd)
    stdout, stderr, status = Open3.capture3(cmd)
    raise stderr unless status.success?

    stdout.chomp.downcase == 'true'
  end

  def vm_change_switch(vm_name, switch_name, verbosity = 0)
    script_path = File.expand_path('../scripts/Change-vSwitch.ps1', __dir__)
    cmd = [
      'PowerShell',
      '-File', script_path,
      '-VMName', vm_name,
      '-SwitchName', switch_name
    ]
    if verbosity.positive?
      printf "Running command: %<command>s\n",
             command: cmd.map { |arg| arg.include?(' ') ? %("#{arg}") : arg }.join(' ')
    end
    system(*cmd, exception: true)
  end
end
