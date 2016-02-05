### Script to migrate imap mailboxes from Exchange server to Cyrus server

#### 1. Description


- This script uses `imapsync` (https://github.com/imapsync/imapsync) to synchronize IMAP mailboxes from Exchange 2013 to Cyrus. Basically, this script uses an user on Exchange, which has full access permissions to other users' mailboxes to transfer mailboxes.

- Exchange server must have IMAP server enabled. See more here https://technet.microsoft.com/en-us/library/bb124489%28v=exchg.150%29.aspx

- All IMAP folders will be subscribed

- Folders will not be transferred:

    - Calendar
    - Contacts
    - Journal
    - Notes
    - Tasks
    - RSS Feeds
    - Sync Issues


- Folders will be renamed:

    - Sent Items -> Sent
    - Deleted Items -> Trash
    - Junk Email -> Junk


#### 2. Usage

- Install `imapsync` on your Linux machine.

- Clone this repo into your working place.

- Prepare your input file with format: `email   password`. ( See `users.txt` for example )

- Options: using `-h` for help.


- Tested on:
    - Windows Exchange 2013
    - CentOS 6.5
    - imapsync 1.644
    - Cyrus 2.3.16

#### 3. License

See [LICENSE](../master/LICENSE)
