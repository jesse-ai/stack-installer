```markdown
# Jesse AI Installation Script

Enhanced installation script for Jesse AI trading bot on Ubuntu 22.04.

## Improvements Over Original Script

1. Enhanced Error Handling
   - Comprehensive error logging
   - Line number tracking for errors
   - Detailed installation logs
   - Command verification checks

2. Better Python Environment Management
   - Configurable Python version
   - Proper virtual environment setup
   - Consistent pip usage
   - Removed deprecated packages

3. Improved Security
   - Dedicated configuration directory
   - Proper file permissions
   - Configuration backups
   - Secure package installation

4. System Service Management
   - Proper Redis service configuration
   - PostgreSQL database setup
   - Service status verification
   - Automated database user creation

5. Shell Environment
   - Support for both bash and zsh
   - Modular configuration
   - Environment variable management
   - Automatic shell detection

## Prerequisites

- Ubuntu 22.04 LTS
- Root access or sudo privileges
- Minimum 2GB RAM
- 20GB disk space

## Installation

1. Download the installation script:
```bash
wget https://raw.githubusercontent.com/your-repo/install-jesse.sh
chmod +x install-jesse.sh
```

2. Run the script:
```bash
./install-jesse.sh
```

## Post-Installation

1. Create a new project:
```bash
cd /opt/jesse
git clone https://github.com/jesse-ai/project-template my-bot
cd my-bot
cp .env.example .env
```

2. Configure .env file with your settings
3. Start Jesse:
```bash
source /opt/jesse_env/bin/activate
jesse run
```

## Common Issues

1. If you see "Command not found" after installation:
   - Re-login or run: `source ~/.bashrc`

2. If Redis fails to start:
   - Check logs: `systemctl status redis-server`

3. If PostgreSQL connection fails:
   - Verify database: `sudo -u postgres psql -c "\l" | grep jesse_db`
   - Check .env configuration

## Maintenance

- Logs are stored in: `/var/log/jesse_install.log`
- Configuration directory: `/opt/jesse/config`
- Virtual environment: `/opt/jesse_env`
```
