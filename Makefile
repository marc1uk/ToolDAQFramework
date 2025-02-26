ZMQLib= -L ../zeromq-4.0.7/lib -lzmq 
ZMQInclude= -I ../zeromq-4.0.7/include/ 

BoostLib= -L ../boost_1_66_0/install/lib -lboost_date_time -lboost_serialization  -lboost_iostreams -lz
BoostInclude= -I ../boost_1_66_0/install/include/

DataModelInclude =
DataModelLib =

MyToolsInclude =
MyToolsLib =

all: lib/libMyTools.so lib/libToolChain.so lib/libStore.so include/Tool.h lib/libServiceDiscovery.so lib/libDataModel.so lib/libLogging.so RemoteControl NodeDaemon main

main: src/main.cpp lib/libStore.so lib/libLogging.so lib/libToolChain.so lib/libServiceDiscovery.so | lib/libMyTools.so  lib/libDataModel.so 
	@echo -e "\n*************** Making " $@ "****************"
	g++  src/main.cpp -o main -I include -L lib -lStore -lMyTools -lToolChain -lDataModel -lLogging -lServiceDiscovery -lpthread $(DataModelInclude) $(MyToolsInclude) $(ZMQLib) $(ZMQInclude) $(BoostLib) $(BoostInclude)


lib/libStore.so: src/Store/*

	@echo -e "\n*************** Making " $@ "****************"
	cp src/Store/*.h include/
	g++  -shared -fPIC -I include src/Store/*.cpp -o lib/libStore.so $(BoostLib) $(BoostInclude)


include/Tool.h: src/Tool/Tool.h

	@echo -e "\n*************** Making " $@ "****************"
	cp src/Tool/Tool.h include/
	cp UserTools/*.h include/
	cp UserTools/*/*.h include/
	cp DataModel/*.h include/	

lib/libToolChain.so: src/ToolChain/* lib/libStore.so include/Tool.h lib/libServiceDiscovery.so lib/libLogging.so |  lib/libDataModel.so lib/libMyTools.so 

	@echo -e "\n*************** Making " $@ "****************"
	cp src/ToolChain/ToolChain.h include/
	g++  -fPIC -shared src/ToolChain/ToolChain.cpp -I include -lpthread -L lib -lStore -lDataModel -lMyTools -lServiceDiscovery -lLogging -o lib/libToolChain.so $(DataModelInclude) $(MyToolsInclude) $(ZMQLib) $(ZMQInclude) $(BoostLib) $(BoostInclude)



clean: 

	@echo -e "\n*************** Cleaning up ****************"
	rm -f include/*.h
	rm -f lib/*.so
	rm -f main
	rm -f RemoteControl
	rm -f NodeDaemon
	rm -f UserTools/*/*.o
	rm -f DataModel/*.o

lib/libDataModel.so: DataModel/* lib/libLogging.so lib/libStore.so  $(patsubst DataModel/%.cpp, DataModel/%.o, $(wildcard DataModel/*.cpp))

	@echo -e "\n*************** Making " $@ "****************"
	cp DataModel/*.h include/
	#g++  -fPIC -shared DataModel/*.cpp -I include -L lib -lStore -lLogging -o lib/libDataModel.so $(DataModelInclude) $(DataModelLib) $(ZMQLib) $(ZMQInclude) $(BoostLib) $(BoostInclude)
	g++  -fPIC -shared DataModel/*.o -I include -L lib -lStore -lLogging -o lib/libDataModel.so $(DataModelInclude) $(DataModelLib) $(ZMQLib) $(ZMQInclude) $(BoostLib) $(BoostInclude)


lib/libMyTools.so: UserTools/*/* UserTools/* lib/libStore.so include/Tool.h lib/libLogging.so $(patsubst UserTools/%.cpp, UserTools/%.o, $(wildcard UserTools/*/*.cpp))| lib/libDataModel.so 

	@echo -e "\n*************** Making " $@ "****************"
	cp UserTools/*.h include/
	cp UserTools/*/*.h include/
	#g++   -shared -fPIC UserTools/Factory/Factory.cpp -I include -L lib -lStore -lDataModel -lLogging -o lib/libMyTools.so $(MyToolsInclude) $(DataModelInclude) $(MyToolsLib) $(ZMQLib) $(ZMQInclude) $(BoostLib) $(BoostInclude)
	g++   -shared -fPIC UserTools/*/*.o -I include -L lib -lStore -lDataModel -lLogging -o lib/libMyTools.so $(MyToolsInclude) $(DataModelInclude) $(MyToolsLib) $(ZMQLib) $(ZMQInclude) $(BoostLib) $(BoostInclude)

RemoteControl: src/RemoteControl/* lib/libStore.so lib/libServiceDiscovery.so

	@echo -e "\n*************** Making " $@ "****************"
	g++  src/RemoteControl/RemoteControl.cpp -o RemoteControl -I include -L lib -lStore -lServiceDiscovery $(ZMQLib) $(ZMQInclude) $(BoostLib) $(BoostInclude)

NodeDaemon: src/NodeDaemon/* lib/libStore.so lib/libServiceDiscovery.so
	@echo -e "\n*************** Making " $@ "****************"
	g++  src/NodeDaemon/NodeDaemon.cpp -o NodeDaemon -I ./include/ -L ./lib/ -lServiceDiscovery -lStore $(ZMQInclude) $(ZMQLib) $(BoostLib) $(BoostInclude)

lib/libServiceDiscovery.so: src/ServiceDiscovery/* lib/libStore.so
	@echo -e "\n*************** Making " $@ "****************"
	cp src/ServiceDiscovery/ServiceDiscovery.h include/
	g++  -shared -fPIC -I include src/ServiceDiscovery/ServiceDiscovery.cpp -o lib/libServiceDiscovery.so -L lib/ -lStore  $(ZMQInclude) $(ZMQLib) $(BoostLib) $(BoostInclude)

lib/libLogging.so: src/Logging/*  lib/libStore.so 
	@echo -e "\n*************** Making " $@ "****************"
	cp src/Logging/Logging.h include/
	g++  -shared -fPIC -I include src/Logging/Logging.cpp -o lib/libLogging.so -L lib/ -lStore $(ZMQInclude) $(ZMQLib) $(BoostLib) $(BoostInclude)

UserTools/%.o: UserTools/%.cpp lib/libStore.so include/Tool.h lib/libLogging.so lib/libDataModel.so
	@echo -e "\n*************** Making " $@ "****************"
	cp $(shell dirname $<)/*.h include
	-g++ -c -fPIC -o $@ $< -I include -L lib -lStore -lDataModel -lLogging $(MyToolsInclude) $(MyToolsLib) $(DataModelInclude) $(DataModelib) $(ZMQLib) $(ZMQInclude) $(BoostLib) $(BoostInclude)

target: remove $(patsubst %.cpp, %.o, $(wildcard UserTools/$(TOOL)/*.cpp))

remove:
	echo "removing"
	-rm UserTools/$(TOOL)/*.o

DataModel/%.o: DataModel/%.cpp lib/libLogging.so lib/libStore.so  
	@echo -e "\n*************** Making " $@ "****************"
	cp $(shell dirname $<)/*.h include
	-g++ -c -fPIC -o $@ $< -I include -L lib -lStore -lLogging  $(DataModelInclude) $(DataModelLib) $(ZMQLib) $(ZMQInclude) $(BoostLib) $(BoostInclude)
