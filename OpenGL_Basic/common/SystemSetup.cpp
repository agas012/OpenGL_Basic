#include "SystemSetup.hpp"

SystemSetup::SystemSetup() {}
SystemSetup::~SystemSetup() {}

bool SystemSetup::readfile()
{
	std::string line;
	std::ifstream conf_file("MyConfig.txt");

	if (conf_file.is_open())
	{
		getline(conf_file, line, '=');
		conf_file >> configProperties.source;
	}
	else
	{
		return false;
	}
	conf_file.close();
	return true;
}

ConfigProperties SystemSetup::getall()
{
	return configProperties;
}