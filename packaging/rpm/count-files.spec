Name:		count-files
Version:	1.0
Release:	1%{?dist}
Summary:	Enhanced script to count files with configuration support

License:	MIT
URL:		https://github.com/DerkachIvan/linux-lab-scripts
Source0:	%{name}-%{version}.tar.gz
BuildArch:	noarch
Requires:	bash
Requires:	coreutils
Requires:	findutils

%description
A Bash script that counts the number of regular files
in the /etc directory, excluding directories and symbolic links.

%pre
if [ "$EUID" -ne 0 ]; then
    echo "Помилка: пакет count-files потрібно встановлювати від root"
    exit 1
fi

echo "Починається встановлення пакета count-files..."


%prep
%setup -q

%install
mkdir -p %{buildroot}%{_bindir}
#mkdir -p %{buildroot}%{_mandir}/man1

install -m 755 count_files.sh %{buildroot}%{_bindir}/count_files
#install -m 644 man/count_files.1 %{buildroot}%{_mandir}/man1/

%post
echo "Пакет count-files успішно встановлено"

# Конфігурація count-files
TARGET_DIR=/etc
EXTENSION=*

echo "Для запуску використовуйте команду: count_files"


%files
%{_bindir}/count_files
#%{_mandir}/man1/count_files.1*

%changelog
* Sat Jan 10 2026 Derkach Ivan <vanyaderkach229@gmail.com> - 1.0-1
- Added --help option
- Added human-readable size output
