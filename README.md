# WCCC: Working Copy Codea Client

A [Codea](http://codea.io) program that connects Codea to [Working Copy](http://workingcopyapp.com), a full-featured iOS Git client.

## Contents

1. [Features](#features)
1. [Installation](#installation)
  a. [About WebDAV](#about-webdav)
2. [Usage](#usage)
  a. [Single Project Repositories](#single-project-repositories)
  b. [Multiple project repositories](#multiple-project-repositories)
3. [Tutorial](#tutorial)

##Features

* Browse all of your repositories from within Codea

* Link remote files and folders to Codea projects for two-way version control

* Switch branches in Working Copy, or checkout an earlier version of your project, then pull that version into Codea

* Easily import multi-file repositories that don't have installers with WCCC's "Copy as single file" feature, which concatenates the remote files using Codea's "paste into project" format

* SHA1 authentication verifies write operations and warns you if you are in danger of overwriting data

Brings the full power of Git source control and social coding to Codea. When you switch to a different branch of your repository, or checkout a previous version, those changes are reflected in the Working Copy WebDAV. This makes it easy to switch between different branches of a project, or to pull a previous version of the project into Codea. All of this is done locally, on device. No web connection is needed. When you get back online, you can merge your changes with your remote repositories on GitHub or BitBucket. WCCC's support for Codea's paste-into-project format means that you can easily install multi-file Git repositories in Codea.

## Installation

Getting everything installed is a bit fiddly. But, you only have to follow these steps once, and then you're flying.

1. You need the apps Codea and Working Copy installed on your iPad.

2. Install [Soda](https://github.com/Utsira/Soda#installation) in Codea (this handles the GUI of WCCC).

3. Install WCCC in Codea: Copy the entire contents of `Working Copy Codea Client installer.lua` to the clipboard. In Codea project screen, long-press "+ Add New Project", and select "Paste into project". Run the installer. After installing WCCC, it will quit with an error saying that Soda is not installed.

4. Make Soda a dependency of WCCC: In the code editor of the WCCC project, press the + sign in the top-right corner and put a check in the box next to "Soda".

5. WCCC uses 2 technologies to communicate with Working Copy: x-callback URLs and WebDAV. These both need to be setup. When you first run WCCC a dialog will prompt you to enter the x-callback key and WebDAV URL, and and giving you a button to switch to Working Copy and activate the WebDAV. 
  ![The Activate WevDAV prompt](https://puffinturtle.files.wordpress.com/2015/10/image4.jpeg)
  Ignore the text entry fields and press the "Activate WebDAV" button. Working Copy will become foregrounded, and you will see a red error message warning you that the x-callback key is incorrect. Press the red error message, and Working Copy will open the x-callback settings pane. Copy the x-callback key to your clipboard:  
  ![x-callback settings](https://puffinturtle.files.wordpress.com/2015/10/image5.jpeg) 
  Now, staying in Working Copy, go to the WebDAV settings pane. Currently, there is no support for digest authentication in Codea (I'm  looking into whether this can be implemented now that Codea has sockets). Therefore, you will have to delete the contents of both the WebDAV username and the password fields (so they are both blank), and turn off remote connections. This means that Working Copy's WebDAV will only run on-device (ie only other apps on your iPad can see it). It is highly recommended that you do not turn on remote connections without a password and username set. The URL should be `http://localhost:8080/`
  ![WebDAV settings](https://puffinturtle.files.wordpress.com/2015/10/image.jpeg)
  
  6. You can now switch back to Codea and to WCCC using your favourite app switching method (eg a 4-finger swipe right, or, on iOS 9, by pressing the "Back to Codea" button in the top-right corner. Paste the x-callback key into the text entry field. 
  
  ![WCCC settings window](https://puffinturtle.files.wordpress.com/2015/10/image6.jpeg)
  
  > ###About WebDAV
  > When WorkingCopy is in the background, the WebDAV server is shut off after a few minutes. WCCC detects this and automatically wakes the WebDAV up again. When this happens you'll see the same prompt that you saw on launch telling you that the WebDAV needs to be woken up. 
  > 
  > When you press "Activate WebDAV", Working Copy will be foregrounded or opened, the WebDAV started, and then an automatic switch back to Codea will occur.

## Change log

### v1.1

+ WCCC now pushes and pulls projects using a flat folder structure (ie the lua files and the Info.plist files all in a single folder), in order to make it compatible with Codea 2.3.2's "export zipped project" and the older "export Xcode project" features. This flat structure is also much simpler to handle when using WebDAV. Previously, the lua files were in a `tabs` folder 1 level down from `Info.plist`. If you wish to pull from a repo created with an old version of WCCC, you'll need to move the `Info.plist` file into the same folder as the lua files yourself. 

+ SHA1 verification for write/push has been switched off, as it was too slow for large repos, and return "verfication failed" reports when he write had in fact succeeded (if a tab was renamed or deleted).
  
## Usage 

Browse your Working Copy repositories by selecting folders and files in the "Finder" pane on the left. The "< Open in Working Copy" button in the top-left of the menu bar will open the selected repository in Working Copy. The close button in the top-right corner of the display exits WCCC back to Codea.

WCCC is designed to be compatible with Codea 2.3.2's "export zipped project", and the earlier "export xcode project" format. The project's tabs are saved as individual `.lua` files alongside its `Info.plist` file are saved to a single folder, named `[projectName].codea` by default. The `Info.plist` file contains the order that the tabs are in in Codea. 

![Example repository](https://puffinturtle.files.wordpress.com/2015/10/image1.png)

##### Copy as a single file

Multiple lua files are concatenated together in "paste into project" format. If WCCC sees an `Info.plist` file in the root of the repository, it reads that first to determine the order to concatenate the lua files in. If additional lua files are found not mentioned in `Info.plist`, these will be added to the end of the concatenate-ed file. If no `Info.plist` file is found, WCCC will concatenate the files in the order in which they appear in the repository (nb this could be wrong, and you might have to reorder the tabs once you paste the project in Codea). WCCC expects to find all of the .lua files in one location (ie a single folder on the root, or just in the root itself), and will only search folders one layer past the root of the repository

##### Link/ Relink

To properly push and pull, you need to link the repository to a Codea project. As currently there is no way to get the list of Codea projects from within Codea, you will have to type in the Codea project name (case sensitive). WCCC remembers the link between the repository path and the Codea project, so you only have to type in this name once. Once linked, push and pull become available as actions

##### Push

Pushes the linked project to the repository. Info.plist is pushed to the root, and the tabs are pushed to a `/tabs/` folder. If you have pushed to the remote before, SHA1 authentication is used to check whether the remote has changed since you last pushed. Following the write, a further SHA1 verification checks that the push succeeded (issue: the verification frequently fails if files have been renamed or deleted. Switching to Working Copy, then back to Codea and pushing again seems to fix this). If the project is very large, generating the SHA1 keys may take a second or two. A switch to Working Copy button will then open a commit window in Working Copy. This allows you to verify what has changed, select which files to commit, write a commit message, and push to a remote repository if there is one.

##### Pull

Pulls the content of the remote repository into the Codea project. If you have pushed to the remote before, SHA1 authentication is used to check whether you have changed the Codea project since you last pushed. Following the pull, the operation is verified with SHA1 authentication.

##### Push installer to root

Saves an additional `Installer.lua` file to the root of the repository. The installer is a few lines of code that will load, save, and run all of the files contained in the project. This makes it easy for people not using WCCC to install your project, by copying the contents of the installer, and then long pressing on the "add project" button in Codea's main screen, and selecting "paste into project". The installer files that you used to install Soda and WCCC were created in this way. In order to create installer files, you need to supply WCCC with the path to your raw github user content,

## Tutorial

#### Cloning a repository and pulling the files into Codea

A quick tutorial. We're going to use WCCC to manage its own source code, so that when updates are posted, they can easily be pulled into Codea. We're going to do this by cloning this repository. A clone is a local copy of a repository that can easily be kept in sync with the online repository. This can be done in just 3 steps.

1. **Copy the URL for this repository.** Git repositories have special addresses that end in .git, but, the regular web URL for repositories on GitHub can be used as an alias for the git address, so go ahead and copy the URL in the Safari address bar (or, hitting Copy in the action menu of iOS Safari also copies the URL)

2. **Clone the repository in Working Copy.** Launch Working Copy. If you are in a repository, press the back button until you get back to the root. At the top of the left-hand file browser pane, press + to add a new repository, and then press "Clone". 
  ![clone dialog](https://puffinturtle.files.wordpress.com/2015/10/image7.jpeg) 
  Working Copy should recognise that you have a GitHub URL in the pasteboard, and will offer to clone the repository. Tap the blue message (if this blue prompt does not appear, just paste the URL into the URL field and press clone). The WCCC repository will be cloned in Working Copy. 

3. **Use WCCC to link the clone in Working Copy to the project in Codea.** Launch WCCC. You will probably have to switch back and forth between Working Copy and WCCC to wake the WebDAV. In WCCC, use the left-hand file browser panel to find the WCCC repository that you just cloned in Working Copy and select it. Press the "Link" button, and in the link dialog that opens, enter whatever name you called WCCC in Codea, and press "Link". 
  ![link dialog](https://puffinturtle.files.wordpress.com/2015/10/image8.jpeg)  
  WCCC will remember the connection between the Working Copy repository and the Codea project. You can now press "Pull" whenever you want to pull the latest version of WCCC into Codea.

