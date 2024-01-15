Name:          libnl3
Version:       3.7.0
Release:       1
Summary:       Providing APIs to netlink protocol based Linux kernel interfaces
License:       LGPLv2
URL:           http://www.infradead.org/~tgr/libnl/
Source:        https://github.com/thom311/libnl/releases/download/libnl3_7_0/libnl-3.7.0.tar.gz

BuildRequires: flex bison libtool autoconf automake swig
Requires:      %{name} = %{version}-%{release}

Provides:      %{name}-cli
Obsoletes:     %{name}-cli

%description
This package contains a collection of libraries providing
APIs to netlink based Linux kernel sockets interfaces.

%package devel
Summary: Libraries and headers for libnl3
Requires: %{name} = %{version}-%{release} kernel-headers

%description devel
This package provides various libraries and headers for using libnl3

%package help
Summary: Document for libnl3
Requires:      %{name} = %{version}-%{release}

Provides:      %{name}-doc = %{version}-%{release}
Obsoletes:     %{name}-doc < %{version}-%{release}

%description help
This package contains libnl3 related documentations

%package -n python3-libnl3
Summary: Python3 binding for libnl3
BuildRequires: python3-devel
Requires: %{name} = %{version}-%{release}

%description -n python3-libnl3
Python3 bindings for libnl3

%prep
%autosetup -n libnl-%{version} -p1

%build
autoreconf -vif
%configure --disable-static
%make_build

cd python
CFLAGS="$RPM_OPT_FLAGS" %py3_build
CFLAGS="$RPM_OPT_FLAGS" %py3_build

%install
%make_install

find $RPM_BUILD_ROOT -name *.la |xargs rm -f

cd python
%py3_install

%check
make check

cd python
%{__python3} setup.py check

%ldconfig_scriptlets

%files
%doc COPYING
%{_libdir}/libnl-*.so.*
%config(noreplace) %{_sysconfdir}/*
%{_libdir}/libnl/
%{_bindir}/*

%files devel
%{_includedir}/libnl3/netlink/
%{_libdir}/*.so
%{_libdir}/pkgconfig/*.pc

%files help
%{_mandir}/man8/*

%files -n python3-libnl3
%{python3_sitearch}/netlink
%{python3_sitearch}/netlink-*.egg-info

%changelog
* Mon Nov 7 2022 chengyechun <chengyechun1@huawei.com> - 3.7.0-1
- Type:enhancement
- ID:NA
- SUG:NA
- DESC:update to libnl-3.7.0

* Wed Mar 10 2021 zengwefeng <zwfeng@huawei.com> - 3.5.0-4
- Type:bugfix
- ID:NA
- SUG:NA
- DESC:add missing check for NULL return from allocate_rfd
       add include netlink private nl-auto-h header
       use proper int type for id attributes
       add RTNL_LINK_REASM_OVERLAPS stat
       check for null pointer in macvlan
       fix leaking in link msg parser
       fix NLE_NOMEM handling in parse multipath

* Thu Oct 29 2020 gaihuiying <gaihuiying1@huawei.com> - 3.5.0-3
- Type:requirement
- ID:NA
- SUG:NA
- DESC:remove python2

* Thu Sep 10 2020 lunankun <lunankun@huawei.com> - 3.5.0-2
- Type: bugfix
- ID: NA
- SUG: NA
- DESC: fix Source0 url

* Sun Jan 12 2020 openEuler Buildteam <buildteam@openeuler.org> - 3.5.0-1
- update software to 3.5.0

* Wed Dec 25 2019 openEuler Buildteam <buildteam@openeuler.org> - 3.4.0-8
- Type:bugfix
- Id:NA
- SUG:NA
- DESC:provides libnl3-doc

* Sat Sep 7 2019 liyongqiang<liyongqiang10@huawei.com> - 3.4.0-7
- Package init
