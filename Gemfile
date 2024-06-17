source 'https://rubygems.org'

# something broke in the CDDL 0.12.1 update (github actions fails to install a native dependency somehow), 
# which I have no idea how to fix, so let's try to fix the version at 0.11.2 for now...
# another suspect is regexp-examples that required a native plugin since 1.6.0, so punt that to the previous 3 years old as well
# https://rubygems.org/gems/cddl/versions/0.12.1
gem 'regexp-examples', '1.5.1'
gem 'cddl', '0.11.2'