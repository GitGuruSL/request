# Step-by-Step Upload Instructions

## 1. Move your key file
# First, move your downloaded .pem key file to a secure location
# Example: C:\AWS-Keys\request-backend-key.pem

## 2. Set correct permissions (Windows)
# Right-click the .pem file → Properties → Security → Advanced
# Remove all users except your current user and System

## 3. Upload the deployment package
# Replace YOUR-EC2-PUBLIC-IP with your actual EC2 public IP
# Replace PATH-TO-YOUR-KEY with the actual path to your .pem file

# Command template:
scp -i "C:\path\to\request-backend-key.pem" request-backend-deploy.zip ubuntu@YOUR-EC2-PUBLIC-IP:~/

# Example:
# scp -i "C:\AWS-Keys\request-backend-key.pem" request-backend-deploy.zip ubuntu@54.123.456.789:~/

## 4. Connect to your instance
# ssh -i "C:\path\to\request-backend-key.pem" ubuntu@YOUR-EC2-PUBLIC-IP

# Example:
# ssh -i "C:\AWS-Keys\request-backend-key.pem" ubuntu@54.123.456.789
