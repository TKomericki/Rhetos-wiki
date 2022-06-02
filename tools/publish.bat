git pull https://github.com/Rhetos/Rhetos-wiki.git master --ff-only || pause
git pull https://github.com/Rhetos/Rhetos.wiki.git master --ff-only || pause

@rem Contributions wiki repository
git push https://github.com/Rhetos/Rhetos-wiki.git master || pause
@rem Official wiki
git push https://github.com/Rhetos/Rhetos.wiki.git master || pause

@echo.
@echo DONE.
