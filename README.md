# PostgreSQL Password Reset Tool for Windows

A PowerShell script to safely reset your PostgreSQL password when you've been locked out or forgotten your credentials.

## 🎯 What It Does

This script automates the process of resetting the PostgreSQL `postgres` superuser password by:
1. Temporarily modifying authentication settings to allow passwordless access
2. Resetting the password
3. Restoring secure authentication settings
4. Verifying the new password works

## ⚠️ Prerequisites

- **Windows OS** (PowerShell required)
- **PostgreSQL installed** (any version)
- **Administrator privileges** (required to modify configuration files and restart services)
- **psql** command-line tool (included with PostgreSQL installation)

## 🚀 Quick Start

### Step 1: Download the Script

Clone this repository or download the script:
```bash
git clone https://github.com/morganmwenda/RESET-POSTGRESQL-PASSWORD.git
cd RESET-POSTGRESQL-PASSWORD
```

### Step 2: Run as Administrator

1. Right-click on **PowerShell**
2. Select **"Run as Administrator"**
3. Navigate to the script directory
4. Run the script:

```powershell
.\reset-postgres-password.ps1
```

### Step 3: Follow the Progress

The script will display progress through 7 steps:
```
[1/7] Finding PostgreSQL service...
[2/7] Backing up pg_hba.conf...
[3/7] Modifying authentication to 'trust'...
[4/7] Restarting PostgreSQL service...
[5/7] Resetting postgres user password...
[6/7] Restoring secure authentication...
[7/7] Restarting PostgreSQL with secure settings...
```

## 🔧 Configuration

You can customize the script by modifying these variables at the top:

```powershell
$pgVersion = "18"                                           # Your PostgreSQL version
$pgDataDir = "C:\Program Files\PostgreSQL\$pgVersion\data" # Data directory path
$newPassword = "postgres123"                                # Your desired new password
```

### Common PostgreSQL Data Directory Locations:
- **Default**: `C:\Program Files\PostgreSQL\[VERSION]\data`
- **Custom installations**: Check your installation directory

## 📋 How It Works

1. **Verification**: Checks if running with Administrator privileges
2. **Service Detection**: Automatically finds your PostgreSQL service
3. **Backup**: Creates a backup of `pg_hba.conf` (authentication config file)
4. **Trust Mode**: Temporarily changes authentication to 'trust' (no password required)
5. **Password Reset**: Executes SQL command to change the password
6. **Restore**: Returns authentication settings to secure mode (scram-sha-256/md5)
7. **Test**: Verifies the new password works

## 🔒 Security Notes

- ✅ The script creates a backup of your authentication configuration
- ✅ Secure authentication is automatically restored after password reset
- ✅ The script runs checks to prevent common errors
- ⚠️ The default password (`postgres123`) should be changed for production use
- ⚠️ Only run this script on systems you have authorization to access

## 🛠️ Troubleshooting

### "This script must be run as Administrator"
**Solution**: Right-click PowerShell and select "Run as Administrator"

### "PostgreSQL service not found"
**Solution**: 
- Verify PostgreSQL is installed
- Check Windows Services (`services.msc`) for postgresql service
- The service name usually contains "postgresql"

### "Cannot find path to pg_hba.conf"
**Solution**: 
- Update `$pgVersion` to match your installed version
- Or set `$pgDataDir` to your actual data directory path

### "psql is not recognized"
**Solution**: 
Add PostgreSQL bin directory to your PATH:
```powershell
$env:Path += ";C:\Program Files\PostgreSQL\18\bin"
```

### Permission Denied Errors
**Solution**: 
- Ensure no other programs are accessing PostgreSQL files
- Check that PostgreSQL service can be restarted
- Verify you have write permissions to the data directory

## 📦 What Gets Modified

| File | Change | Restored? |
|------|--------|-----------|
| `pg_hba.conf` | Authentication temporarily set to 'trust' | ✅ Yes |
| PostgreSQL service | Restarted twice | ✅ Yes |
| postgres user | Password changed | ❌ No (this is the goal) |

## 🔄 Recovery

If something goes wrong, the script automatically:
1. Restores the backup of `pg_hba.conf`
2. Restarts PostgreSQL with original settings

You can also manually restore:
```powershell
Copy-Item "C:\Program Files\PostgreSQL\18\data\pg_hba.conf.backup" `
          "C:\Program Files\PostgreSQL\18\data\pg_hba.conf" -Force
Restart-Service postgresql-x64-18
```

## 📝 Default Credentials After Reset

```
Username: postgres
Password: postgres123
```

**Remember to change this password for production systems!**

## 🎓 Additional Commands

After resetting your password, you can use these commands:

```powershell
# Set password environment variable
$env:PGPASSWORD = "postgres123"

# Connect to PostgreSQL
psql -U postgres

# Create a new database
psql -U postgres -c "CREATE DATABASE mydb;"

# List all databases
psql -U postgres -c "\l"
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

## ⚡ Version Support

This script has been tested with:
- PostgreSQL 12, 13, 14, 15, 16, 17, 18
- Windows 10, Windows 11
- Windows Server 2016, 2019, 2022

## 📞 Support

If you encounter issues:
1. Check the [Troubleshooting](#-troubleshooting) section
2. Review PostgreSQL logs in `data/log` directory
3. Open an issue on GitHub with error details

## ⭐ Acknowledgments

- Built for the PostgreSQL community
- Inspired by common password recovery needs
- Uses official PostgreSQL tools and best practices

---

## ⚠️ Disclaimer

- This tool is for legitimate password recovery on systems you own or have permission to access. Always follow your organization's security policies.

## ⚖️ Denial of Liability

- The tool is provided "as is" without any warranties, express or implied. The creator, developer, and distributors of this tool shall not be held liable for any direct, indirect, incidental,     special, exemplary, or consequential damages (including, but not limited to, procurement of substitute goods or services; loss of use, data, or profits; or business interruption) however        caused and on any theory of liability, whether in contract, strict liability, or tort (including negligence or otherwise) arising in any way out of the use of this tool, even if advised of      the possibility of such damage.

- The user is solely responsible for verifying their legal right to use this tool on any given system.
