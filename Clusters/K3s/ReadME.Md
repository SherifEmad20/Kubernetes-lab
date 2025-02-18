# Installation of k3s Cluster on macOS

## Requirements:

- Homebrew package manager
- VM Manager (Multipass)

### Steps:

1. **Install Homebrew on macOS**

   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. **Install Multipass on macOS**

   ```bash
   brew install multipass --cask
   ```

3. **Create a VM for k3s**

   ```bash
   multipass launch --name k3s --memory 8G --disk 20G
   ```

4. **Access the VM shell**

   ```bash
   multipass shell <VM name>
   ```

5. **Install k3s**
   ```bash
   curl -sfL https://get.k3s.io | sh -
   ```

### Configure Remote Desktop on the Ubuntu VM:

6. **Install Microsoft Remote Desktop**

   ```bash
   brew install --cask microsoft-remote-desktop
   ```

7. **Update and install xRDP**

   ```bash
   sudo apt update
   sudo apt install neofetch
   sudo apt install ubuntu-desktop xrdp
   sudo systemctl enable xrdp
   sudo ufw allow from any to any port 3389 proto tcp

   # Set a password for the machine to be able to connect to it via the remote desktop
   sudo passwd ubuntu
   <add the password>
   ```

8. **Check IP Address**

   ```bash
   multipass list
   # The IPv4 corresponding to the VM name
   ```

9. **Modifying VM Resources**
   ```bash
   multipass stop <instance name>
   multipass set local.<instance name>.cpus=4
   multipass set local.<instance name>.disk=60G
   multipass set local.<instance name>.memory=7G
   ```

### Setting Up Multi-Node k3s Cluster

#### Configure Node Hostnames

On the master node:

```bash
hostnamectl set-hostname master
```

On worker nodes:

```bash
hostnamectl set-hostname worker-1
```

#### Configure Master Node

1. **Create the `config.yaml` file** to designate the node as the master:

   ```bash
   cat <<EOF > /etc/rancher/k3s/config.yaml
   cluster-init: true
   EOF
   ```

2. **Restart the k3s cluster**

   ```bash
   systemctl restart k3s
   ```

3. **Retrieve the node token**

   ```bash
   sudo cat /var/lib/rancher/k3s/server/node-token
   ```

4. **Get the master node IP**

   ```bash
   ip a | grep inet
   ```

5. **Apply taint on the master node**

   ```bash
   kubectl taint nodes master node-role.kubernetes.io/control-plane=true:NoSchedule
   ```

   - The taint is applied to ensure that the scheduler assigns workloads to worker nodes rather than the master node.

- To remove taint:
  ```bash
  kubectl taint nodes master node-role.kubernetes.io/control-plane:NoSchedule-
  ```

#### Install k3s on Worker Nodes

1. **Install k3s agent on worker nodes**

   ```bash
   curl -sfL https://get.k3s.io | K3S_URL="https://<master_node_ip>:6443" K3S_TOKEN="<master_node_token>" sh -
   ```

2. **Check agent status**
   ```bash
   sudo systemctl status k3s-agent
   ```

#### Configure Firewall if Needed

```bash
sudo ufw allow 6443/tcp
sudo ufw allow 10250/tcp
sudo ufw allow 8472/udp
sudo ufw allow 51820/udp
sudo ufw allow 51821/udp
```

#### Copy Kubeconfig File from Master to Worker Nodes

1. On master node copy the kubeconfig file:

   ```bash
   vi /etc/rancher/k3s/k3s.yaml
   ```

2. On worker nodes paste the kubeconfig file:

   ```bash
   vi /etc/rancher/k3s/k3s.yaml
   ```

3. On worker export the kubeconfig file:
   ```bash
   export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
   ```
