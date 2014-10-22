ECHO Setting env variables...

ECHO %1

if "%1"=="-d" (
	CALL %JEKYLL_PATH%setpath.cmd
	START jekyll serve & ping 1.1.1.1 -n 1 -w 10000 > nul  & START http://localhost:4000/ & EXIT
	EXIT
) else (
	CALL %JEKYLL_PATH%setpath.cmd
	jekyll %1
)