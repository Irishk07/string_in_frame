CXX = g++

LIBS = -lsfml-graphics -lsfml-window -lsfml-audio -lsfml-system

CPPSRC = patcher.cpp
CPPOBJ := $(CPPSRC:%.cpp=build/%.o)
HEADER_DEPENDS := $(CPPOBJ:%.o=%.d)

.PHONY: all
all: build patch_prog

build:
	mkdir -p build

$(CPPOBJ): build/%.o: %.cpp | build
	@$(CXX) -MP -MMD -c $< -o $@

patch_prog: $(CPPOBJ) 
	@$(CXX) $^ -o $@ $(LIBS)

-include $(HEADER_DEPENDS)

.PHONY: clean
clean:
	rm -f build/*.o
	rm -f build/*.d