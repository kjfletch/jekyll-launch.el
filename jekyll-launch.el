;;; jekyll-launch.el
;;
;; Author: Kevin J. Fletcher <kevinjohn.fletcher@googlemail.com>
;; Maintainer: Kevin J. Fletcher <kevinjohn.fletcher@googlemail.com>
;; Keywords: jekyll, weblog
;; Homepage: http://github.com/kjfletch/jekyll-launch.el
;; Version: 0.2 - prerelease.
;; 
;;; Commentary
;;
;; This file defines functions that aid in weblog development when
;; using jekyll <http://github.com/mojombo/jekyll>
;;
;; Functionality includes:
;;  * launching jekyll
;;  * launching a jekyll development server
;;  * killing a jekyll development server
;;  * inserting new posts into a jekyll project
;;
;; These functions will attempt to find a jekyll project for the
;; current working buffer/file/directory by progressing up the
;; directory tree.
;;
;; Copyright (C) 2010 Kevin J. Fletcher
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;
;;; Code

(defun jekyll-launch ()
  "Launch jekyll for the current project to generate your site.
Interactive wrapper."
  (interactive)
  (jekyll-launch-do-if-found-project 'jekyll-launch-do 
				     "jekyll"))

(defun jekyll-launch-server()
  "Launch a jekyll development server for the current project.
Interactive wrapper."
  (interactive)
  (jekyll-launch-do-if-found-project 'jekyll-launch-server-do
				     "jekyll"))

(defun jekyll-launch-kill-server ()
  "Kill a jekyll development server for the current project.
Interactive wrapper."
  (interactive)
  (jekyll-launch-do-if-found-project 'jekyll-launch-kill-server-do))

(defun jekyll-launch-new-post ()
  "Create a new post in the current jekyll project.
Interactive wrapper."
  (interactive)
  (jekyll-launch-do-if-found-project 'jekyll-launch-new-post-do))

(defun jekyll-launch-do-if-found-project (func &rest arguments)
  "Call the given function, with the passed arguments if a project
folder can be found. First argument is always the project directory."
  (let ((dir (jekyll-launch-find-project)))
    (if dir
	(apply func dir arguments)
      (message "Could not find Jekyll project."))))

(defun jekyll-launch-find-project()
  "Find a jekyll project by looking in the current working directory
and climbing the directory tree until one is found or we run out of
places to search."
  (jekyll-launch-find-project-do default-directory nil))

(defun jekyll-launch-do (project-dir cmd)
  "Launch jekyll for a given project."
  (let ((default-directory project-dir)
	(procname (concat "jekyll:" project-dir)))

    (if (get-buffer procname)
	(kill-buffer procname))
    
    (call-process cmd nil procname t)
    (view-buffer-other-window procname)))

(defun jekyll-launch-server-do (project-dir cmd)
  "Launch a jekyll development server for a given project."
  (let ((default-directory project-dir)
	(procname (concat "jekyllserver:" project-dir)))

    (jekyll-launch-kill-server-do project-dir)
    (start-process procname procname cmd "--server")
    (view-buffer-other-window procname)))

(defun jekyll-launch-kill-server-do (project-dir)
  "Programatically kill a jekyll development server for a given project."
  (let ((procname (concat "jekyllserver:" project-dir)))
    (if (get-process procname)
	(delete-process procname))))

(defun jekyll-launch-new-post-do (project-dir)
  "For a given jekyll project directory create a new post."
  ;; fixme: this function assumes textile format will be used!
  ;;        maybe use ido to select from a list of known formats?
  (let* ((todaydate (format-time-string "%Y-%m-%d"))
	(postsdir  (concat project-dir "_posts/"))
	(title 
	 (replace-regexp-in-string "-+"  "-"
             (replace-regexp-in-string "[^a-zA-Z0-9]" "-"
	         (read-from-minibuffer "Post Title: "))))
	(format "textile")
	(filename (concat postsdir todaydate "-" title "." format)))
    (find-file filename)))

(defun jekyll-launch-find-project-do (dir prev-dir)
  "Look in the given directory for the footprint of a jekyll project.
If the footprint is found then return the directory. If not, repeat the
search in the parent directory. If no parent directory exists, return nil.
This is achieved by recursion."
  (let ((default-directory dir)
	(config-file "_config.yml")
	(layouts-dir "_layouts")
	(posts-dir "_posts"))
    (if (and (not (eq nil prev-dir))
	     (string= (file-truename dir) (file-truename prev-dir)))
	nil ;; We have stopped moving up the directory tree, bomb out!
      (if (or (file-exists-p config-file)
	      (file-exists-p layouts-dir)
	      (file-exists-p posts-dir))
	  dir ;; We have found a jekyll project directory!
	(progn
	  (cd "..") ;; Move to the parent directory
	  (jekyll-launch-find-project-do default-directory dir))))))
  
(provide 'jekyll-launch)

;;; jekyll-launch.el ends here.