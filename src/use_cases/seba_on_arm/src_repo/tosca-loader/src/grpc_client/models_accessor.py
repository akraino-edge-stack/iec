
# Copyright 2017-present Open Networking Foundation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

from xosconfig import Config
from multistructlog import create_logger
log = create_logger(Config().get('logging'))

from resources import RESOURCES

class GRPCModelsAccessor:
    """
    This class provide the glue between the models managed by TOSCA and the ones living in xos-core
    """

    @staticmethod
    def get_model_from_classname(class_name, data, username, password):
        """
        Give a Model Class Name and some data, check if that exits or instantiate a new one
        """

        # NOTE: we need to import this later as it's generated by main.py
        from KEYS import TOSCA_KEYS

        # get the key for this model
        try:
            filter_keys = TOSCA_KEYS[class_name]
        except KeyError, e:
            raise Exception("[XOS-TOSCA] Model %s doesn't have a tosca_key specified" % (class_name))

        if len(filter_keys) == 0:
            raise Exception("[XOS-TOSCA] Model %s doesn't have a tosca_key specified" % (class_name))

        filter = {}
        for k in filter_keys:
            if isinstance(k, str):
                try:
                    filter[k] = data[k]
                except KeyError, e:
                    raise Exception("[XOS-TOSCA] Model %s doesn't have a property for the specified tosca_key (%s)" % (class_name, e))
            elif isinstance(k, list):
                # one of they keys in this list has to be set
                one_of_key = None
                for i in k:
                    if i in data:
                        one_of_key = i
                        one_of_key_val = data[i]
                if not one_of_key:
                    raise Exception("[XOS-TOSCA] Model %s doesn't have a property for the specified tosca_key_one_of (%s)" % (class_name, k))
                else:
                    filter[one_of_key] = one_of_key_val

        key = "%s~%s" % (username, password)
        if not key in RESOURCES:
            raise Exception("[XOS-TOSCA] User '%s' does not have ready resources" % username)
        if class_name not in RESOURCES[key]:
            raise Exception('[XOS-TOSCA] The model you are trying to create (class: %s, properties, %s) is not know by xos-core' % (class_name, str(filter)))

        cls = RESOURCES[key][class_name]

        models = cls.objects.filter(**filter)

        if len(models) == 1:
            model = models[0]
            log.info("[XOS-Tosca] Model of class %s and properties %s already exist, retrieving instance..." % (class_name, str(filter)), model=model)
        elif len(models) == 0:

            if 'must-exist' in data and data['must-exist']:
                raise Exception("[XOS-TOSCA] Model of class %s and properties %s has property 'must-exist' but cannot be found" % (class_name, str(filter)))

            model = cls.objects.new()
            log.info("[XOS-Tosca] Model (%s) is new, creating new instance..." % str(filter))
        else:
            raise Exception("[XOS-Tosca] Model of class %s and properties %s has multiple instances, I can't handle it" % (class_name, str(filter)))

        return model