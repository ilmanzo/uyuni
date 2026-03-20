# Copyright (c) 2026 SUSE LLC.
# Licensed under the terms of the MIT license.

require_relative 'remote_node'

# The K8sNode class represents a node running as a pod in Kubernetes.
# It interacts with the pod using kubectl exec.
class K8sNode < RemoteNode
  attr_accessor :namespace, :pod_name

  # Initializes a new Kubernetes node.
  #
  # @param host [String] The logical host name (server, db, proxy).
  # @return [K8sNode] The K8s node.
  def initialize(host)
    @host = host
    @namespace = ENV.fetch('K8S_NAMESPACE', 'default')

    puts "Initializing a Kubernetes node for '#{@host}'."
    
    label = case @host
            when 'server' then 'app=uyuni-server'
            when 'db'     then 'app=uyuni-db'
            when 'proxy'  then 'app=uyuni-proxy'
            else raise(NotImplementedError, "Host #{@host} is not supported in K8s mode.")
            end

    @pod_name = KubernetesHelper.get_pod_name_by_label(label, namespace: @namespace)
    @hostname = @pod_name
    @target = @pod_name
    @full_hostname = "#{@pod_name}.#{@namespace}.svc.cluster.local"

    $named_nodes[host] = @hostname
    $stdout.puts "Host '#{@host}' is alive in K8s as pod #{@pod_name}" unless $build_validation

    # Determine OS version and OS family
    @os_version, @os_family = get_os_version
    @local_os_version, @local_os_family = get_os_version(runs_in_container: false)

    # Public IP for a pod is its pod IP
    cmd = "kubectl get pod #{@pod_name} -n #{@namespace} -o jsonpath='{.status.podIP}'"
    @public_ip, _code = get_target('localhost').run_local(cmd, check_errors: false)
    @public_ip.strip!

    $node_by_host[@host] = self
    $host_by_node[self] = @host
  end

  # Runs a command in the pod using kubectl exec.
  #
  # @param cmd [String] The command to run.
  # @param runs_in_container [Boolean] Always true for K8sNode.
  # @param separated_results [Boolean] Whether the results should be stored separately.
  # @param check_errors [Boolean] Whether to check for errors or not.
  # @param timeout [Integer] The timeout to be used, in seconds.
  # @param successcodes [Array<Integer>] Success codes.
  # @param buffer_size [Integer] Buffer size.
  # @param verbose [Boolean] Verbose mode.
  # @param exec_option [Boolean] Ignored for K8sNode.
  # @return [Array<String, String, Integer>] The output, error, and exit code.
  def run(cmd, runs_in_container: true, separated_results: false, check_errors: true, timeout: DEFAULT_TIMEOUT, successcodes: [0], buffer_size: 65_536, verbose: false, exec_option: '-i')
    # For K8sNode, we always run in the "container" (the pod)
    cmd_prefixed = "kubectl exec -n #{@namespace} #{@pod_name} -- #{cmd}"
    # Use localhost to run the kubectl command
    get_target('localhost').run_local(cmd_prefixed, separated_results: separated_results, check_errors: check_errors, timeout: timeout, successcodes: successcodes, buffer_size: buffer_size, verbose: verbose)
  end

  # Check if a file exists in the pod.
  #
  # @param file [String] The path of the file to check.
  # @return [Boolean] Returns true if the file exists, false otherwise.
  def file_exists?(file)
    _out, code = run("test -f #{file}", check_errors: false)
    code.zero?
  end

  # Check if a folder exists in the pod.
  #
  # @param file [String] The path of the folder to check.
  # @return [Boolean] Returns true if the folder exists, false otherwise.
  def folder_exists?(file)
    _out, code = run("test -d #{file}", check_errors: false)
    code.zero?
  end

  # Delete a file in the pod.
  #
  # @param file [String] The path of the file to be deleted.
  # @return [Integer] The exit code.
  def file_delete(file)
    _out, code = run("rm #{file}", check_errors: false)
    code
  end

  # Delete a folder in the pod.
  #
  # @param folder [String] The path of the folder to be deleted.
  # @return [Integer] The exit code.
  def folder_delete(folder)
    _out, code = run("rm -rf #{folder}", check_errors: false)
    code
  end
end
