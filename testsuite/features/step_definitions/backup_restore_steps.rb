# Copyright (c) 2017-2026 SUSE LLC.
# Licensed under the terms of the MIT license.

# Step definitions for mgradm backup and restore operations

BACKUP_DIR = '/var/lib/containers/storage/volumes/test_backup'.freeze

# Helper method to check if backup files exist in the specified directory
def backup_exists?
  target = get_target('server')
  output, _code = target.run("find #{BACKUP_DIR} -maxdepth 1 -type f -name '*.tar*'", runs_in_container: false)
  root_level = !output.lines.empty?
  output, _code = target.run("find #{BACKUP_DIR} -mindepth 2 -type f -name '*.tar*'", runs_in_container: false)
  sub_level = !output.lines.empty?
  root_level && sub_level
end

# Helper method to clean up backup files after tests
def cleanup!
  # remove any test backup files if the scenario fails to prevent interference with subsequent tests
  get_target('server').run("rm -rf #{BACKUP_DIR}", runs_in_container: false)
end

When('When I backup the server excluding the spacewalk volume') do
  command = "mgradm backup create #{BACKUP_DIR} --skipvolumes srv-spacewalk"
  @last_command_output = get_target('server').run(command, runs_in_container: false)
end

When('I stop the services on server') do
  get_target('server').run('mgradm stop', runs_in_container: false)
end

When('I start the services on server') do
  get_target('server').run('mgradm start', runs_in_container: false)
end

When('I successfully restore the backup') do
  command = "mgradm backup restore #{BACKUP_DIR} --force"
  @last_command_output = get_target('server').run(command, runs_in_container: false)
end

Then('the command should succeed') do
  raise "Command failed with output: #{@last_command_output}" if @last_command_output.nil?
end

Then('the backup must exist') do
  raise "Backup directory #{BACKUP_DIR} does not contain any tar files." unless backup_exists?
end

Then(/^service "(.*)" is running on server$/) do |service|
  target = get_target('server')
  output, _code = target.run("systemctl is-active #{service}", runs_in_container: false)
  raise "Service #{service} is not running." unless output.strip == 'active'
end

When('I remove the backup directory on server') do
  cleanup!
end

After do |scenario|
  if scenario.failed?
    cleanup!
    # if server is stopped due to a previous failure, start it again
    # to ensure the system is in a clean state for subsequent tests
    output, _code = get_target('server').run('systemctl is-active uyuni-server', runs_in_container: false)
    get_target('server').run('mgradm start', runs_in_container: false) unless output.strip == 'active'
  end
end
