# Step 1: Use a lightweight web server as the base
FROM nginx:alpine

# Step 2: Copy your banking app code into the web server's directory
# This replaces the manual 'echo' command we used in Terraform
COPY index.html /usr/share/nginx/html/index.html

# Step 3: Expose port 80 so we can access it
EXPOSE 80

# Step 4: Start Nginx automatically
CMD ["nginx", "-g", "daemon off;"]
