public with sharing class HTMLParser {
	
	// return a list of pseudo objects defined by specified primary tag (object) and list of child tags (fields)
	static public List<Map<String,List<String>>> parse(String html, String parentTag, List<String> childTags, Map<String,List<String>> childTagAttributes, Map<String,integer> childTagOccurrence) {
		// if child tag attributes set, extract the corresponding attribute value instead of the tag value 
		// TODO: requirement: a given child tag can be parsed multiple times (value vs. attribute value) 
		System.debug('@@@ parent tag: ' + parentTag);
		System.debug('@@@ child tags: ' + childTags);
		List<Map<String,List<String>>> objects = new List<Map<String,List<String>>>();
		integer idx = 0; // tracks the current position in the file (cursor position)
		integer eof = html.length();
		System.debug('@@@ eof: ' + eof);
		integer parentTagLen = parentTag.length();
		System.debug('@@@ parent tag length: ' + parentTagLen);
		// a parent tag defines the start of an object
		// to check for nested tags, identify the tag fragment w/o any attributes
		// find the first blank space within (1) or a contiguous closure (2) else assume a fragment is provided
		integer parentTagFragmentEnd = parentTag.indexOf(' ');
		if (parentTagFragmentEnd < 0) {
			parentTagFragmentEnd = parentTag.indexOf('>');
            if (parentTagFragmentEnd < 0) parentTagFragmentEnd = parentTag.length();
		}
		System.debug('@@@ parent tag fragment ends at: ' + parentTagFragmentEnd);
		String parentTagFragment = parentTag.left(parentTagFragmentEnd);
		System.debug('@@@ parent tag fragment: ' + parentTagFragment);
		String parentTagClose = parentTagFragment.replace('<','</') + '>';
		System.debug('@@@ parent tag close: ' + parentTagClose);
		integer parentTagCloseLen = parentTagClose.length();
		System.debug('@@@ parent tag close length: ' + parentTagCloseLen);
		while (idx <= eof) {
			idx = html.indexOf(parentTag,idx);
			System.debug('@@@ parent tag found at index: ' + idx);
			if (idx == -1) {
				return objects;
			}
			integer objectEndIdx;
			// handle nesting: check for the next tag starting index and compare against end
			// keep seeking until no nested tags are found
			integer nextParentTagFragment = html.indexOf(parentTagFragment,idx + 1);
			System.debug('next parent tag fragment found?: ' + nextParentTagFragment);
			integer nextCloseTag = html.indexOf(parentTagClose,idx + 1);
			System.debug('next close tag found?: ' + nextCloseTag);
			if (nextParentTagFragment > 0 
					&& nextCloseTag > 0 
					&& nextParentTagFragment < nextCloseTag) {
				System.debug('@@@ nested tags detected');
				System.debug('@@@ next parent tag fragment found at: ' + nextParentTagFragment);
				System.debug('@@@ next parent close tag found at: ' + nextCloseTag);
				while (nextParentTagFragment > 0 
						&& nextCloseTag > 0
							&& nextParentTagFragment < nextCloseTag) {
					nextCloseTag = html.indexOf(parentTagClose,nextCloseTag + 1);
					System.debug('@@@ next close tag found at: ' + nextCloseTag);
					nextParentTagFragment = html.indexOf(parentTagFragment,nextParentTagFragment + 1);
					System.debug('@@@ next parent tag found at: ' + nextParentTagFragment);
				} // end while
			} // end if
			objectEndIdx = (nextCloseTag + parentTagCloseLen);
			System.debug('@@@ object is closed at index: ' + objectEndIdx);
			String parentTagEnclosure = html.substring(idx,objectEndIdx);
			System.debug('@@@ parent tag enclosure (object): ' + parentTagEnclosure);
			// loop through the contents of the tag enclosure and pick out the values for the child tags specified
			Map<String,List<String>> tagValueMap = new Map<String,List<String>>();
			// assumption is the first child tag will be the key for the map
			for (String s : childTags) {
				tagValueMap.put(s,new List<String>());
				Boolean findChildByFragment = false;
				System.debug('@@@ child tag: ' + s);
				integer childTagFragmentEnd = s.indexOf(' ');
				if (childTagFragmentEnd == -1) {
					childTagFragmentEnd = s.indexOf('>');
					if (childTagFragmentEnd == -1) {
						findChildByFragment = true;
						childTagFragmentEnd = s.length();
					}
				} 
				System.debug('@@@ childTagFragmentEnd: ' + childTagFragmentEnd);
				String childTagFragment = s.left(childTagFragmentEnd);
				System.debug('@@@ child tag fragment: ' + childTagFragment);
				integer childTagLen = s.length();
				System.debug('@@@ child tag length: ' + childTagLen);
				String childTagClose = childTagFragment.replace('<','</') + '>';
				System.debug('@@@ child tag close: ' + childTagClose);
				integer childObjectIdx = parentTagEnclosure.indexOf(s);
                System.debug('@@@ child object index (first occurrence): ' + childObjectIdx);
				// if a recurring tag within the pseudo object, check whether a particular instance is requested
				if (childTagOccurrence != null && childTagOccurrence.containsKey(s) && childTagOccurrence.get(s) != null) {
					System.debug('@@@ in child tag occurrence conditional ...');
                    System.debug('@@@ read occurrence ' + childTagOccurrence.get(s)  + ' for tag ' + s);
                    if (childTagOccurrence.get(s) > 1) {
						for (integer j=2;j <= childTagOccurrence.get(s);j++) {
							childObjectIdx = parentTagEnclosure.indexOf(s,childObjectIdx + 1);
                            System.debug('@@@ child object index: ' + childObjectIdx);
						}
					}
				}
				System.debug('@@@ child tag is found at: ' + childObjectIdx);
				// move to the next child tag if not found
				if (childObjectIdx == -1) continue; 
				integer childTagEnd = parentTagEnclosure.indexOf('>',childObjectIdx);
				System.debug('@@@ child tag ends at index: ' + childTagEnd);
				integer childObjectEndIdx = parentTagEnclosure.indexOf(childTagClose,childObjectIdx + childTagLen);
				System.debug('@@@ child tag enclosure (object) ends at index: ' + childObjectEndIdx);
				String childTagEnclosure = parentTagEnclosure.substring(childObjectIdx, childObjectEndIdx + childTagClose.length());
				System.debug('@@@ child tag enclosure (object): ' + childTagEnclosure);
				integer valueReadStart = (childTagEnd + 1);
				System.debug('@@@ value read start at: ' + valueReadStart);
				integer valueReadEnd = childObjectEndIdx;
				System.debug('@@@ value read end at: ' + valueReadEnd);
				String tagValue = parentTagEnclosure.substring(valueReadStart,valueReadEnd);
                System.debug('@@@ tag value assigned: ' + tagValue);
				if (childTagAttributes != null && childTagAttributes.containsKey(s) && childTagAttributes.get(s) != null) {
					System.debug('@@@ in child tags conditional ...');
                    for (String t : childTagAttributes.get(s)) {
						if (!String.isBlank(t)) {
							tagValue = getAttributeValue(childTagEnclosure,t);
                            System.debug('@@@ tag value from attribte: ' + tagValue);
						}
						tagValue = removeComments(tagValue);
						tagValue = tagValue.trim();
						System.debug('@@@ tag value: ' + tagValue);
						tagValueMap.get(s).add(tagValue);
					}
				} else {
					tagValue = removeComments(tagValue);
					tagValue = tagValue.trim();
					System.debug('@@@ tag value: ' + tagValue);
					tagValueMap.get(s).add(tagValue);
				}
			} // end while
			System.debug('@@@ child tags map: ' + tagValueMap);
			objects.add(tagValueMap);
			idx = objectEndIdx;
			System.debug('@@@ index incremented to: ' + idx);
		} // end while
		System.debug('@@@ objects (map) returned: ' + objects);
		return objects;
	}

	public static String removeComments(String s) {
		integer sLen = s.length();
		System.debug('@@@ string length: ' + sLen);
		String stringToReturn;
		integer commentLoc = s.indexOf('<!--');
		System.debug('@@@ comment found at: ' + commentLoc);
		if (commentLoc >= 0) {
			stringToReturn = s.left(commentLoc);
			System.debug('@@@ string to return (partial): ' + stringToReturn);
			integer commentEnd = s.indexOf('-->',commentLoc) + 3;
			System.debug('@@@ comment ends at: ' + commentEnd);
			stringToReturn = (stringToReturn + s.right(sLen - commentEnd));
			System.debug('@@@ stringToReturn: ' + stringToReturn);
			if (stringToReturn.indexOf('<!--') >= 0) {
				stringToReturn = removeComments(stringToReturn);
			} 
		} else {
			stringToReturn = s;
		}
		return stringToReturn;
	}

	public static String getAttributeValue(String tagValue, String attributeName) {
		String valueToReturn = '';
		System.debug('@@@ tag value: ' + tagValue);
		System.debug('@@@ attribute name: ' + attributeName);
		if (!String.isBlank(tagValue) && !String.isBlank(attributeName)) {
			integer attributeIdx = tagValue.indexOf(attributeName);
			if (attributeIdx >= 0) {
				integer valueStart = tagValue.indexOf('"',attributeIdx) + 1;
				integer valueEnd = tagValue.indexOf('"',valueStart + 1);
				if (valueStart >= 0 && valueEnd >= 0) {
					valueToReturn = tagValue.substring(valueStart,valueEnd);
				}
			}
		}
		System.debug('@@@ value to return: ' + valueToReturn);
		return valueToReturn;
	}

}