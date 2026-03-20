# Copyright (c) 2026 SUSE LLC
# Licensed under the terms of the MIT license.

# Step definitions for Kubernetes-specific features.

When(/^I delete the pod with label "([^"]*)"$/) do |label|
  pod_name = KubernetesHelper.get_pod_name_by_label(label)
  namespace = ENV.fetch('K8S_NAMESPACE', 'default')
  _out, code = get_target('localhost').run_local("kubectl delete pod #{pod_name} -n #{namespace}")
  raise "Failed to delete pod #{pod_name}" unless code.zero?
end

When(/^I wait until the pod with label "([^"]*)" is running$/) do |label|
  namespace = ENV.fetch('K8S_NAMESPACE', 'default')
  repeat_until_timeout(timeout: DEFAULT_TIMEOUT, message: "Pod with label '#{label}' not running in #{namespace}") do
    cmd = "kubectl get pods -n #{namespace} -l #{label} -o jsonpath='{.items[0].status.phase}'"
    phase, _code = get_target('localhost').run_local(cmd, check_errors: false)
    break if phase.strip == 'Running'

    sleep 5
  end
end

When(/^I wait until the pod with label "([^"]*)" is ready$/) do |label|
  KubernetesHelper.wait_for_pod_ready(label)
end

Then(/^the logs of pod with label "([^"]*)" should contain no startup errors$/) do |label|
  pod_name = KubernetesHelper.get_pod_name_by_label(label)
  forbidden_patterns = [
    /FATAL/,
    /StandardWrapper\.Throwable/,
    /NullPointerException/,
    /ConnectionRefusedException/
  ]
  # Add specific whitelist if needed
  whitelist = [
    "This is a harmless warning",
    "Ignoring non-critical exception"
  ]
  
  error_lines = KubernetesHelper.scan_pod_logs(pod_name, forbidden_patterns, whitelist: whitelist, since: '1h')
  raise "Critical errors found in logs of #{pod_name}:\n#{error_lines.join("\n")}" unless error_lines.empty?
end

Then(/^the logs of pod with label "([^"]*)" should contain the success string "([^"]*)"$/) do |label, success_string|
  pod_name = KubernetesHelper.get_pod_name_by_label(label)
  namespace = ENV.fetch('K8S_NAMESPACE', 'default')
  cmd = "kubectl logs -n #{namespace} #{pod_name} --since=1h"
  logs, _code = get_target('localhost').run_local(cmd, check_errors: false)
  raise "Success string '#{success_string}' not found in logs of #{pod_name}" unless logs.include?(success_string)
end
