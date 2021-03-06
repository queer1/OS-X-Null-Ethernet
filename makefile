# really just some handy scripts...

KEXT=NullEthernet.kext
DIST=RehabMan-NullEthernet

ifeq ($(findstring 32,$(BITS)),32)
OPTIONS:=$(OPTIONS) -arch i386
endif

ifeq ($(findstring 64,$(BITS)),64)
OPTIONS:=$(OPTIONS) -arch x86_64
endif

.PHONY: all
all: ssdt-rmne.aml
	xcodebuild build $(OPTIONS) -scheme NullEthernet -configuration Debug
	xcodebuild build $(OPTIONS) -scheme NullEthernet -configuration Release

.PHONY: clean
clean:
	xcodebuild clean $(OPTIONS) -scheme NullEthernet -configuration Debug
	xcodebuild clean $(OPTIONS) -scheme NullEthernet -configuration Release
	
.PHONY: update_kernelcache
update_kernelcache:
	sudo touch /System/Library/Extensions
	sudo kextcache -update-volume /

.PHONY: install_debug
install_debug:
	sudo cp -R ./Build/Debug/$(KEXT) /System/Library/Extensions
	make update_kernelcache

.PHONY: install
install:
	sudo cp -R ./Build/Release/$(KEXT) /System/Library/Extensions
	make update_kernelcache
	
.PHONY: install_inject
install_inject:
	sudo cp -R ./Build/Release/$(KEXT) /System/Library/Extensions
	sudo cp -R ./Build/Release/NullEthernetInjector.kext /System/Library/Extensions
	make update_kernelcache

.PHONY: distribute
distribute:
	if [ -e ./Distribute ]; then rm -r ./Distribute; fi
	mkdir ./Distribute
	cp -R ./Build/Debug ./Distribute
	cp -R ./Build/Release ./Distribute
	rm -Rf ./Distribute/Debug/NullEthernetInjector.kext
	mv ./Distribute/Release/NullEthernetInjector.kext ./Distribute
	cp patch.txt ./Distribute
	cp ssdt-rmne.aml ./Distribute
	find ./Distribute -path *.DS_Store -delete
	find ./Distribute -path *.dSYM -exec echo rm -r {} \; >/tmp/org.voodoo.rm.dsym.sh
	chmod +x /tmp/org.voodoo.rm.dsym.sh
	/tmp/org.voodoo.rm.dsym.sh
	rm /tmp/org.voodoo.rm.dsym.sh
	ditto -c -k --sequesterRsrc --zlibCompressionLevel 9 ./Distribute ./Archive.zip
	mv ./Archive.zip ./Distribute/`date +$(DIST)-%Y-%m%d.zip`

ssdt-rmne.aml : ssdt-rmne.dsl
	iasl -p $@ $^

