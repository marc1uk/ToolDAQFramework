#ifndef SERVICES_H
#define SERVICES_H

#include <ServiceDiscovery.h>
#include <zmq.hpp>
#include <iostream>
#include <string>
#include <thread>
#include <chrono>
#include <functional>
#include <SlowControlCollection.h>
#include <boost/uuid/uuid.hpp>            // uuid class
#include <boost/uuid/uuid_generators.hpp> // generators
#include <boost/uuid/uuid_io.hpp>         // streaming operators etc.
#include <boost/date_time/posix_time/posix_time.hpp>
#include <boost/progress.hpp>
#include <ServicesBackend.h>

#define SERVICES_DEFAULT_TIMEOUT 1800

namespace ToolFramework {

  struct Plot {
    std::string name;
    std::string title;
    std::string xlabel;
    std::string ylabel;
    std::vector<float> x;
    std::vector<float> y;
    Store info;
  };
  
  
  class Services{
    
    
  public:
    
    Services();
    ~Services();
    bool Init(Store &m_variables, zmq::context_t* context_in, SlowControlCollection* sc_vars_in, bool new_service=false);
    bool Ready(const unsigned int timeout=10000); // default service discovery broadcast period is 5s, middleman also checks intermittently, compound total time should be <10s...
    
    bool SQLQuery(const std::string& database, const std::string& query, std::vector<std::string>& responses, const unsigned int timeout=SERVICES_DEFAULT_TIMEOUT);
    bool SQLQuery(const std::string& database, const std::string& query, std::string& response, const unsigned int timeout=SERVICES_DEFAULT_TIMEOUT);
    bool SQLQuery(const std::string& database, const std::string& query, const unsigned int timeout=SERVICES_DEFAULT_TIMEOUT);
    
    bool SendLog(const std::string& message, unsigned int severity=2, const std::string& device="", const unsigned int timestamp=0);
    bool SendAlarm(const std::string& message, unsigned int level=0, const std::string& device="", const unsigned int timestamp=0, const unsigned int timeout=SERVICES_DEFAULT_TIMEOUT);
    bool SendMonitoringData(const std::string& json_data, const std::string& device="", unsigned int timestamp=0);
    bool SendCalibrationData(const std::string& json_data, const std::string& description, const std::string& device="", unsigned int timestamp=0, int* version=nullptr, const unsigned int timeout=SERVICES_DEFAULT_TIMEOUT);
    bool GetCalibrationData(std::string& json_data, int version=-1, const std::string& device="", const unsigned int timeout=SERVICES_DEFAULT_TIMEOUT);
    bool SendDeviceConfig(const std::string& json_data, const std::string& author, const std::string& description, const std::string& device="", unsigned int timestamp=0, int* version=nullptr, const unsigned int timeout=SERVICES_DEFAULT_TIMEOUT);
    bool SendRunConfig(const std::string& json_data, const std::string& name, const std::string& author, const std::string& description, unsigned int timestamp=0, int* version=nullptr, const unsigned int timeout=SERVICES_DEFAULT_TIMEOUT);
    bool GetDeviceConfig(std::string& json_data, const int version=-1, const std::string& device="", const unsigned int timeout=SERVICES_DEFAULT_TIMEOUT);
    bool GetRunConfig(std::string& json_data, const int config_id, const unsigned int timeout=SERVICES_DEFAULT_TIMEOUT);
    bool GetRunConfig(std::string& json_data, const std::string& name, const int version=-1, const unsigned int timeout=SERVICES_DEFAULT_TIMEOUT);
    bool GetRunDeviceConfig(std::string& json_data, const int runconfig_id, const std::string& device="", int* version=nullptr, const unsigned int timeout=SERVICES_DEFAULT_TIMEOUT);
    bool GetRunDeviceConfig(std::string& json_data, const std::string& runconfig_name, const int runconfig_version=-1, const std::string& device="", int* version=nullptr, const unsigned int timeout=SERVICES_DEFAULT_TIMEOUT);
    bool SendROOTplot(const std::string& plot_name, const std::string& draw_options, const std::string& json_data, bool persistent=false, int* version=nullptr, const unsigned int timestamp=0, const unsigned int timeout=SERVICES_DEFAULT_TIMEOUT);
    bool SendTemporaryROOTplot(const std::string& plot_name, const std::string& draw_options, const std::string& json_data, int* version=nullptr, const unsigned int timestamp=0);
    bool SendPersistentROOTplot(const std::string& plot_name, const std::string& draw_options, const std::string& json_data, int* version=nullptr, const unsigned int timestamp=0, const unsigned int timeout=SERVICES_DEFAULT_TIMEOUT);
    bool GetROOTplot(const std::string& plot_name, int& version, std::string& draw_option, std::string& json_data, std::string* timestamp=nullptr, const unsigned int timeout=SERVICES_DEFAULT_TIMEOUT);
    bool SendPlot(Plot& plot, unsigned timeout=SERVICES_DEFAULT_TIMEOUT);
    bool GetPlot(const std::string& name, Plot& plot, unsigned timeout=SERVICES_DEFAULT_TIMEOUT);
    
    SlowControlCollection* GetSlowControlCollection();
    SlowControlElement* GetSlowControlVariable(std::string key);
    bool AddSlowControlVariable(std::string name, SlowControlElementType type, std::function<std::string(const char*)> change_function=nullptr, std::function<std::string(const char*)> read_function=nullptr);
    bool RemoveSlowControlVariable(std::string name);
    void ClearSlowControlVariables();
    
    bool AlertSubscribe(std::string alert, std::function<void(const char*, const char*)> function);
    bool AlertSend(std::string alert, std::string payload);
    
    std::string PrintSlowControlVariables();
    std::string GetDeviceName();
    
    template<typename T> T GetSlowControlValue(std::string name){
      return (*sc_vars)[name]->GetValue<T>();
    }
    
    // a function that calls another function repeatedly for a duration
    template<typename F, typename... Args>
    //double CallForDuration(int timeout_ms, F func, Args&&... args){
    double CallForDuration(int timeout_ms, F func, Args&&... args){
      std::chrono::high_resolution_clock::time_point tfirst = std::chrono::high_resolution_clock::now();
      int max_call_time=0;
      int n_calls=0;
      int max_calls=100;
      while(true){
        std::chrono::high_resolution_clock::time_point tstart = std::chrono::high_resolution_clock::now();
        auto ret = func(std::forward<Args>(args)...);
        std::chrono::high_resolution_clock::time_point tend = std::chrono::high_resolution_clock::now();
        if(ret) return ret;
        int call_time_ms = std::chrono::duration_cast<std::chrono::milliseconds>(tend-tstart).count();
        if(call_time_ms > max_call_time) max_call_time = call_time_ms;
        int total_time = std::chrono::duration_cast<std::chrono::milliseconds>(tend-tfirst).count();
        int time_left = timeout_ms - total_time;
        if((time_left < 0) || (max_call_time > time_left)){
          return ret;
        }
        ++n_calls;
        if(n_calls>max_calls) return ret;
        if(call_time_ms < 2) sleep(1);
      }
      return 0; // dummy
    }
    
    SlowControlCollection* sc_vars;
    
  private:
    
    zmq::context_t* m_context;
    ServicesBackend m_backend_client;
    std::string m_dbname;
    std::string m_name;
    
    
  };
  
}

#endif
