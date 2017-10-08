.SILENT: ;  # no need for @

# To store downloaded files.
CACHE := download-cache

# So we know where we are.
WD := $(shell pwd)
BIN := $(WD)/bin

# Get our lowercased system type. (linux, darwin)
UNAME:= $(shell sh -c 'uname -s 2>/dev/null || echo not')
UNAME:= $(shell echo $(UNAME) | tr '[:upper:]' '[:lower:]')

TFM_VERSION := 0.10.7
TFM_FILENAME := terraform_$(TFM_VERSION)_$(UNAME)_amd64.zip
TFM_DOWNLOAD_URL := https://releases.hashicorp.com/terraform/$(TFM_VERSION)/$(TFM_FILENAME)
TFM_CHECKSUM_FILENAME := terraform_$(TFM_VERSION)_SHA256SUMS
TFM_CHECKSUMS_URL := https://releases.hashicorp.com/terraform/$(TFM_VERSION)/$(TFM_CHECKSUM_FILENAME)
TFM_CMD := $(BIN)/terraform

export TF_VAR_access_key := $(AWS_ACCESS_KEY_ID)
export TF_VAR_secret_key := $(AWS_SECRET_ACCESS_KEY)
export TF_VAR_region := $(AWS_DEFAULT_REGION)

# install installs the terraform binary
install:
	echo "Installing terraform in $(WD)/bin/"
	## Create download cache if it doesn't exist...
	mkdir -p $(WD)/$(CACHE)
	## Fetch terraform and sha sums...
	(cd $(CACHE) && curl -O $(TFM_DOWNLOAD_URL) && curl -O $(TFM_CHECKSUMS_URL))
	## Verify checksum...
	(cd $(CACHE) && grep -q `shasum -a 256 $(TFM_FILENAME)` $(TFM_CHECKSUM_FILENAME))
	## Make bin directory if it doesn't exist.
	mkdir -p $(BIN)
	## Unpack into the bin dir.
	(cd $(WD)/bin && unzip -o $(WD)/$(CACHE)/$(TFM_FILENAME))
	echo -n "Installed terraform: " &&  $(BIN)/terraform --version
	echo "Done..."

apply:
	$(TFM_CMD) apply

destroy:
	$(TFM_CMD) destroy

init:
	$(TFM_CMD) init

plan:
	$(TFM_CMD) plan

show:
	$(TFM_CMD) show

clean:
	rm -fR proxy_api.zip

build:
	zip -9 proxy_api.zip simple.py
