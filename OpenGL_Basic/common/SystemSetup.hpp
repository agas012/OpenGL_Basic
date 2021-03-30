#pragma once
#ifndef SYSTEMSETUP_HPP
#define SYSTEMSETUP_HPP

#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <cstdlib>
#include "ConfigProperties.h"

class SystemSetup
{
	ConfigProperties configProperties;
public:
	SystemSetup();
	~SystemSetup();
	bool readfile();
	ConfigProperties getall();

};

#endif