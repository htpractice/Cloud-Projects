output "key_name" {
  value = aws_key_pair.generated_key.key_name
  description = "value of the key_name"
}


# Output the jenkins repository URL
output "jenkins_app_repo_url" {
  value = aws_ecr_repository.jenkins_app_repo.repository_url
}

# Output the movie client repository URL
output "movie_app_client_repo_url" {
  value = aws_ecr_repository.movie_app_client_repo.repository_url
}

# Output the movie server repository URL
output "movie_app_server_repo_url" {
  value = aws_ecr_repository.movie_app_server_repo.repository_url
  
}
#Output for the bastion host
output "bastion_host" {
  value = module.bastion.public_ip
}

#Output for the Jenkins host
output "jenkins_host" {
  value = module.jenkins.private_ip
}

#Output for the app instances
output "app_instances" {
  value = module.app[*].private_ip
}

#Output for the Windows bastion host
output "windows_bastion_host" {
  value = module.windows_bastion.public_ip
}
