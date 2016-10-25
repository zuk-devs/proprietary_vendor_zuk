copy_files := $(subst $(LOCAL_PATH)/,, \
	$(filter-out %.mk,\
	$(patsubst ./%,%, \
	$(shell find $(LOCAL_PATH) -type f -name "*" -and -not -name ".*") \
	)))

PRODUCT_COPY_FILES += $(foreach file,$(copy_files),\
    $(LOCAL_PATH)/$(file):$(file))
