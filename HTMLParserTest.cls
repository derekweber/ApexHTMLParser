@isTest
private class HTMLParserTest {
	
	private static final String HTML_RESOURCE_NAME = '';
    private static final String HTML_RESOURCE_NAME_BLOG = '';
	private static String htmlContent;
    private static String htmlContent2;

	private static void init() {
        StaticResource sr = [SELECT Id, Body FROM StaticResource WHERE Name = :HTML_RESOURCE_NAME];
        htmlContent = sr.Body.toString();
        sr = [SELECT Id, Body FROM StaticResource WHERE Name = :HTML_RESOURCE_NAME_BLOG];
        htmlContent2 = sr.Body.toString();
	}

	static testMethod void parsePageContent() {
		init();
        String articleTag = '<div>';
        List<String> childTags = new List<String>{'<a ','<div class="type--fineprint">','<div class="rich-text news-listing__rte rhythm-deep">'};
        List<Map<String,List<String>>> objects = HTMLParser.parse(htmlContent,articleTag,childTags,null,null);
        System.debug('@@@ objects returned from parse: ' + objects);
	}

	static testMethod void parsePageContentComplex() {
		init();
        String articleTag = '<article';
        List<String> childTags = new List<String>{'<a ','<p>'};
        Map<String,List<String>> childTagAttributesMap = new Map<String,List<String>>();
        childTagAttributesMap.put('<a ',new List<String>());
        childTagAttributesMap.get('<a ').add('title'); // get the text value first
        childTagAttributesMap.get('<a ').add('href'); // get the link second
        childTagAttributesMap.put('<img ', new List<String>());
        childTagAttributesMap.get('<img ').add('src');
        Map<String,integer> occurrenceMap = new Map<String,integer>();
        occurrenceMap.put('<a ',2);
        occurrenceMap.put('<img ',1);
        List<Map<String,List<String>>> objects = HTMLParser.parse(htmlContent2,articleTag,childTags,childTagAttributesMap,occurrenceMap);
        System.debug('@@@ objects returned from parse: ' + objects);
        // System.assert(objects[0].get('<a')[0]==);
        // System.assert(objects[0].get('<a')[1]==);
	}
    
    
	static testMethod void parseSimpleContent() {
		htmlContent = '<div><a href="#">test</a><div>x</div><div>y</div><span>value_a</span><div class="a">a</div></div>';
		htmlContent += '<div><a href="#">test 2</a><div>x2</div><div>y2</div><span>value_b</span><div class="a">b</div></div>';
        String articleTag = '<div>';
        List<String> childTags = new List<String>{'<span>','<div class="a">'};
        List<Map<String,List<String>>> objects = HTMLParser.parse(htmlContent,articleTag,childTags,null,null);
        System.debug('@@@ objects returned from parse: ' + objects);
        System.assert(objects.size()==2);
        System.assert(objects[0].get('<span>')[0]=='value_a');
        System.assert(objects[0].get('<div class="a">')[0]=='a');
        System.assert(objects[1].get('<span>')[0]=='value_b');
        System.assert(objects[1].get('<div class="a">')[0]=='b');
	}

	private static testMethod void testCommentRemoval() {
		String s = 'some value <!-- some comment --> another value';
		s = HTMLParser.removeComments(s);
		System.assert(s == 'some value  another value');
		String s2 = 'some value <!-- some comment --> another value <!-- another comment -->';
		s2 = HTMLParser.removeComments(s2);
		System.assert(s2 == 'some value  another value ');
	}
	
    private static testMethod void testAttributeGet() {
        String tag = '<a href="https://login.salesforce.com" class="test">test</a>';
        String href = HTMLParser.getAttributeValue(tag,'href');
        System.debug('@@@ href: ' + href);
        System.assert(href=='https://login.salesforce.com');
        String className = HTMLParser.getAttributeValue(tag,'class');
        System.debug('@@@ className: ' + className);
        System.assert(className=='test');
    }
}