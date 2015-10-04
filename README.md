# WCCC: Working Copy Codea Client

A [Codea](http://codea.io) program that connects Codea to [Working Copy](http://workingcopyapp.com), a full-featured iOS Git client.

Brings the full power of Git source control and social coding to Codea. When you switch to a different branch of your repository, or checkout a previous version, those changes are reflected in the Working Copy WebDAV. This makes it easy to switch between different branches of a project, or to pull a previous version of the project into Codea. All of this is done locally, on device. No web connection is needed. When you get back online, you can merge your changes with your remote repositories on GitHub or BitBucket. WCCC's support for Codea's paste-into-project format means that you can easily install multi-file Git repositories in Codea.

## Installation

Getting everything installed is a bit fiddly. But, you only have to follow these steps once, and then you're flying.

1. You need the apps Codea and Working Copy installed on your iPad.

2. Install [Soda](https://github.com/Utsira/Soda#installation) in Codea (this handles the GUI of WCCC).

3. Install WCCC in Codea: Copy the entire contents of `Working Copy Codea Client installer.lua` to the clipboard. In Codea project screen, long-press "+ Add New Project", and select "Paste into project".

4. Make Soda a dependency of WCCC: In the code editor of the WCCC project, press the + sign in the top-right corner and put a check in the box next to "Soda".

5. WCCC uses 2 technologies to communicate with Working Copy: x-callback URLs and WebDAV. These both need to be turned on in Working Copy settings.

  - Turn on x-callbacks and copy the key to your clipboard:
  
    ![x-callback settings](https://puffinturtle.files.wordpress.com/2015/10/image5.jpeg)
  
  - Currently, there is no support for digest authentication in Codea (I'm  looking into whether this can be implemented now that Codea has sockets). Therefore, you will have to clear both the username and the password fields, and turn off remote connections. This means that Working Copy's WebDAV will only run on-device (ie only other apps on your iPad can see it). It is highly recommended that you do not turn on remote connections without a password and username set. The URL should be `http://localhost:8080/`
  
  ![WebDAV settings](https://puffinturtle.files.wordpress.com/2015/10/image.jpeg)
  
  6. The first time you run WCCC you will get a dialog prompting you to enter your x-callback key and the WebDAV URL. Paste the key into the text entry field. WCCC will then wake the WebDAV. Switch back to Codea and start working.
  
  > ###About WebDAV
  > When WorkingCopy is in the background, the WebDAV server is shut off after a few minutes. WCCC detects this and automatically wakes the WebDAV up again. When this happens you'll see a prompt telling you that the WebDAV needs to be woken up. 
  > ![Prompt to wake the WebDAV](https://puffinturtle.files.wordpress.com/2015/10/image4.jpeg)
  > When you press "Activate WebDAV", Working Copy will be foregrounded or opened, and the WebDAV started. When you see a blue "Connect to WebDAV server at" message in WorkingCopy, you can switch back to Codea, eg with a four-finger app-switch gesture, or, on iOS 9, by pressing the "Back to Codea" button in the top-left corner
  > ![WebDAV is awake](https://puffinturtle.files.wordpress.com/2015/10/image2.jpeg)  
  
## Usage 

Browse your Working Copy repositories by selecting folders and files in the "Finder" pane on the left.

WCCC supports two modes of working with repositories:

### 1. Single Project Repositories. 

This is recommended for working with large projects. The repository houses a single Codea project. The project's tabs are saved as individual `.lua` files in a folder called `/tabs/`. The project's `Info.plist` file is saved to the root of the repository. This file contains the order that the tabs are in in Codea. 

![A repository that houses a single project](https://puffinturtle.files.wordpress.com/2015/10/image1.png)

#### Actions available in Single Project repositories:

##### Copy as a single file

Multiple lua files are concertinaed together in "paste into project" format. If WCCC sees an `Info.plist` file in the root of the repository, it reads that first to determine the order to concertina the lua files in. If additional lua files are found not mentioned in `Info.plist`, these will be added to the end of the concertina-ed file. If no `Info.plist` file is found, WCCC will concertina the files in the order in which they appear in the repository (nb this could be wrong, and you might have to reorder the tabs once you paste the project in Codea). WCCC expects to find all of the .lua files in one location (ie a single folder on the root, or just in the root itself), and will only search folders one layer past the root of the repository

##### Link/ Relink

To properly push and pull, you need to link the repository to a Codea project. As currently there is no way to get the list of Codea projects from within Codea, you will have to type in the Codea project name (case sensitive). WCCC remembers the link between the repository path and the Codea project, so you only have to type in this name once. Once linked, push and pull become available as actions

##### Push

Pushes the linked project to the repository. Info.plist is pushed to the root, and the tabs are pushed to a `/tabs/` folder. If you have pushed to the remote before, SHA1 authentication is used to check whether the remote has changed since you last pushed. Following the write, a further SHA1 verification checks that the push succeeded (issue: the verification frequently fails if files have been renamed or deleted. Switching to Working Copy, then back to Codea and pushing again seems to fix this). If the project is very large, generating the SHA1 keys may take a second or two. A switch to Working Copy button will then open a commit window in Working Copy. This allows you to verify what has changed, select which files to commit, write a commit message, and push to a remote repository if there is one.

##### Pull

Pulls the content of the remote repository into the Codea project. If you have pushed to the remote before, SHA1 authentication is used to check whether you have changed the Codea project since you last pushed. Following the pull, the operation is verified with SHA1 authentication.

##### Push installer to root

Saves an additional `Installer.lua` file to the root of the repository. The installer contains all of the project's tabs, concertinaed together into a single file using Codea's "paste-into-project" format. This makes it easy for people not using WCCC to install your project, by copying the contents of the installer, and then long pressing on the "add project" button in Codea's main screen, and selecting "paste into project". The installer files that you used to install Soda and WCCC were created in this way.
  
### 2. Multiple Project Repositories. 

For smaller projects that don't require an entire repository, you can set a repository to multiple project mode. Codea projects are saved to the root of the repository as single files using Codea's "paste-into-project" format. Add a new project to the repository, or select a file in the finder to bring up actions for the file 

![A file in a multiple-project repository](https://puffinturtle.files.wordpress.com/2015/10/image2.png)

#### Actions available for files in Multiple Project repositories:

##### Copy

Places the file being viewed in the clipboard

##### Link/ Relink

Link the file to a Codea project. Enables Push

##### Push as single file

Pushes the project to the file as a single file in Codea's "paste-into-project" format

##### Pull

(not yet implemented)

