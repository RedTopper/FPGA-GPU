
# Generate list of N vertex shaders, M vertex shaders in shaders/ directory
shopt -s nullglob
vert_shaders=(shaders/*.vert)
frag_shaders=(shaders/*.frag)

first_vert_shader="${vert_shaders[0]}"
first_frag_shader="${frag_shaders[0]}"

# Terminal color codes
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# We are not testing OpenGL linking here, so can test M:1 and 1:M configuration
for i in "${vert_shaders[@]}"
do
    printf "Testing compilation of ${BLUE}${i}${NC} and ${BLUE}${first_frag_shader}${NC} - "
    # Test with -d disabled, and for first test that fails, run again with -d on
    result=$("./glslc_test ${i} ${first_frag_shader} >& /dev/null")
    if [ $result -ne 0 ]; then
        printf "${RED}failed${NC}\n"
        result=$("./glslc_test ${i} ${first_frag_shader} -d")
        exit $result
    fi

    # Otherwise keep going
    printf "${GREEN}passed${NC}\n"

done

for i in "${frag_shaders[@]}"
do
    printf "Testing compilation of ${BLUE}${first_vert_shader}${NC} and ${BLUE}${i}${NC} - "
    # Test with -d disabled, and for first test that fails, run again with -d on
    result=$("./glslc_test ${first_vert_shader} ${i} >& /dev/null")
    if [ $result -ne 0 ]; then
        printf "${RED}failed${NC}\n"
        result=$("./glslc_test ${first_vert_shader} ${i} -d")
        exit $result
    fi

    # Otherwise keep going
    printf "${GREEN}passed${NC}\n"

done

