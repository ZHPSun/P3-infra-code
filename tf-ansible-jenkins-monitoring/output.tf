output "ansible_server_public_ip" {
  value = aws_instance.ansible-server.public_ip

}

output "jenkins_server_public_ip" {
  value = aws_instance.jenkins-server.public_ip

}

output "backend_server_public_ip" {
  value = aws_instance.backend-server.public_ip

}

output "prometheus_server_public_ip" {
  value = aws_instance.prometheus-server.public_ip

}

output "ssh_command_to_ansible_server" {
  value       = <<EOF
  Please do the following:

  1. Copy the SSH key pair to the ansible server:
     scp -i ~/.ssh/${var.public_key_name}.pem ~/.ssh/${var.public_key_name}.pem ec2-user@${aws_instance.ansible-server.public_ip}:~/.ssh

  2. Create the file ~/.ssh/config on the ansible server:
     ssh -i ~/.ssh/${var.public_key_name}.pem ec2-user@${aws_instance.ansible-server.public_ip}
     vim ~/.ssh/config

     Copy the following to the config file:
     ```
       Host ${aws_instance.jenkins-server.public_ip}
           User ec2-user
           IdentityFile ~/.ssh/${var.public_key_name}.pem
     ```

  3. Verify SSH connection to the client:
     ssh -i ~/.ssh/${var.public_key_name}.pem ec2-user@${aws_instance.jenkins-server.public_ip}
  EOF
  description = "SSH command for ansible server setup"
}
