# Path to the pulsar software installation directory e.g:
export ASTROSOFT=/home/psr/software
export PSRHOME=$ASTROSOFT

# OSTYPE
export OSTYPE=linux

# PSRCAT
export PSRCAT_RUNDIR=$ASTROSOFT/psrcat_tar
export PSRCAT_FILE=$ASTROSOFT/psrcat_tar/psrcat.db

# Tempo2
export TEMPO2=$ASTROSOFT/tempo2/T2runtime

# PGPLOT

export PGPLOT_DIR=/usr/lib/pgplot5
export PGPLOT_FONT=/usr/lib/pgplot5/grfont.dat
export PGPLOT_INCLUDES=/usr/include
export PGPLOT_BACKGROUND=white
export PGPLOT_FOREGROUND=black
export PGPLOT_DEV=/xs

# LD_LIBRARY_PATH

LD_LIBRARY_PATH=:/home/psr/software//psrxml/install/lib:/home/psr/software//tempo2/T2runtime/lib:/home/psr/software//psrchive/install/lib

# PATH
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PSRHOME/psrcat_tar:$PSRHOME/psrxml/install/bin:$PSRHOME/tempo2/T2runtime/bin:$PSRHOME/psrchive/install/bin

