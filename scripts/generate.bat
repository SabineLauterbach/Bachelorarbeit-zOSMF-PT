:: Called from Notepad++ Run
:: [path_to_bat_file] "$(CURRENT_DIRECTORY)" "$(NAME_PART)"

:: Change Drive and  to File Directory
::%~d1
::cd %1

:: Run Cleanup
call:cleanup
tskill acrobat  
pdflatex %1.tex
bibtex %1
pdflatex %1.tex
pdflatex %1.tex
makeindex.exe %1.nlo -s nomencl.ist -o %1.nls
pdflatex %1.tex
::START "" %1.pdf

:cleanup
:: del *.log
del *.dvi
del *.aux
del *.bbl
del *.blg
del *.brf
del *.out
goto:eof