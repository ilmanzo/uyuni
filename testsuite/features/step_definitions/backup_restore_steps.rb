# Copyright (c) 2026 SUSE LLC.
# Licensed under the terms of the MIT license.

# @summary Step definitions for mgradm backup and restore operations

When('I backup the server excluding the spacewalk volume') do
  command = "mgradm backup create #{get_context('backup_dir')} --skipvolumes srv-spacewalk"
  @last_command_output = get_target('server').run(command, runs_in_container: false)
end

When('I stop the services on server') do
  get_target('server').run('mgradm stop', runs_in_container: false)
end

When('I start the services on server') do
  get_target('server').run('mgradm start', runs_in_container: false)
end

When('I successfully restore the backup') do
  command = "mgradm backup restore #{get_context('backup_dir')} --force"
  @last_command_output = get_target('server').run(command, runs_in_container: false)
end

Then('the command should succeed') do
  raise "Command failed with output: #{@last_command_output}" if @last_command_output.nil?
end

Then('the backup must exist') do
  raise "Backup directory #{get_context('backup_dir')} does not contain any tar files." unless backup_exists?
end

Then(/^service "(.*)" is running on server$/) do |service|
  target = get_target('server')
  output, _code = target.run("systemctl is-active #{service}", runs_in_container: false)
  raise "Service #{service} is not running." unless output.strip == 'active'
end

When('I remove the backup directory on server') do
  get_target('server').run("rm -rf #{get_context('backup_dir')}", runs_in_container: false)
end
