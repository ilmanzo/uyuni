# Copyright (c) 2026 SUSE LLC.
# Licensed under the terms of the MIT license.

# Helper methods for interacting with Kubernetes clusters.
module KubernetesHelper
  # Returns the name of a pod matching a given label.
  #
  # @param label [String] The label to match (e.g., "app=uyuni-server").
  # @param namespace [String] The Kubernetes namespace to search in.
  # @return [String] The name of the matching pod.
  def self.get_pod_name_by_label(label, namespace: ENV.fetch('K8S_NAMESPACE', 'default'))
    cmd = "kubectl get pods -n #{namespace} -l #{label} -o jsonpath='{.items[0].metadata.name}'"
    # We use backticks or system here because get_target might not be initialized yet
    pod_name = `#{cmd}`
    pod_name.strip
  end

  # Waits for a pod with the given label to be in the "Ready" state.
  #
  # @param label [String] The label to match.
  # @param namespace [String] The Kubernetes namespace.
  # @param timeout [Integer] Maximum time to wait in seconds.
  def self.wait_for_pod_ready(label, namespace: ENV.fetch('K8S_NAMESPACE', 'default'), timeout: DEFAULT_TIMEOUT)
    repeat_until_timeout(timeout: timeout, message: "Pod with label '#{label}' not ready in #{namespace}") do
      cmd = "kubectl get pods -n #{namespace} -l #{label} -o jsonpath='{.items[0].status.containerStatuses[0].ready}'"
      ready = `#{cmd}`
      break if ready.strip == 'true'

      sleep 5
    end
  end

  # Scans pod logs for forbidden error patterns.
  #
  # @param pod_name [String] The name of the pod.
  # @param forbidden_patterns [Array<Regexp>] List of regex patterns that indicate an error.
  # @param whitelist [Array<String>] List of substrings to ignore even if they match a forbidden pattern.
  # @param namespace [String] The Kubernetes namespace.
  # @param since [String] How far back to scan logs (e.g., "10m").
  # @return [Array<String>] List of matching error lines found in the logs.
  def self.scan_pod_logs(pod_name, forbidden_patterns, whitelist: [], namespace: ENV.fetch('K8S_NAMESPACE', 'default'), since: '10m')
    cmd = "kubectl logs -n #{namespace} #{pod_name} --since=#{since}"
    logs = `#{cmd}`
    
    error_lines = []
    logs.each_line do |line|
      next if whitelist.any? { |w| line.include?(w) }
      
      error_lines << line.strip if forbidden_patterns.any? { |p| line =~ p }
    end
    error_lines
  end
end
