;; ox-hugo directory-local settings. See:
;; https://ox-hugo.scripter.co/doc/org-capture-setup/
;; https://ox-hugo.scripter.co/doc/auto-export-on-saving/
;;
;; org-hugo-base-dir is computed from "hugo.toml" rather than hard-coded,
;; so it stays correct no matter how deeply a post is nested under
;; content-org/ (each sample post also sets #+hugo_base_dir explicitly, as
;; a self-contained fallback for batch/CLI export).
((org-mode . ((eval . (when (and buffer-file-name
                                  (string-match-p "/content-org/" buffer-file-name))
                        (require 'ox-hugo nil t)
                        (setq-local org-hugo-base-dir
                                    (locate-dominating-file default-directory "hugo.toml"))
                        (setq-local org-hugo-section "posts")
                        (when (fboundp 'org-hugo-auto-export-mode)
                          (org-hugo-auto-export-mode 1)))))))
