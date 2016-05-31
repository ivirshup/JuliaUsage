# This script adds all possible packages from the julia package manager.
Pkg.update()
run(`apt-get install -y libavcodec-extra-54 libgsl0-dev libmagickwand5`) # Required packages
to_install = Pkg.available()
to_install = symdiff(to_install, ["WCS", "WCSLIB", "Celeste", "SloanDigitalSkySurvey"]) # Have a dependency that won't download
for pkg in Pkg.available()
  try
    Pkg.add(pkg)
  catch x
    warn(x)
  end
end
