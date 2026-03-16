#include <assert.h>
#include <SFML/Graphics.hpp>
#include <SFML/Audio.hpp>
#include <stdio.h>
#include <stdint.h>

#include "patcher.h"



Status Patch(const char* filename, One_patch* all_patches, int patch_count) {
    assert(filename);
    assert(all_patches);

    long correct_size = GetFileSize(CORRECT_FILE);
    long cur_size     = GetFileSize(filename);

    if (correct_size != cur_size)
        return WRONG_FILE;

    unsigned long correct_hash       = Hash(CORRECT_FILE);
    unsigned long correct_patch_hash = Hash(CORRECT_PATCH_FILE);
    unsigned long cur_hash           = Hash(filename);

    if (correct_patch_hash == cur_hash) 
        return ALREADY_PATCHED;

    if (correct_hash != cur_hash)
        return WRONG_FILE;

    FILE* file = fopen(filename, "rb+");
    if (file == NULL) 
        return OPEN_ERROR;

    for (int i = 0; i < patch_count; ++i) {
        fseek(file, all_patches[i].offset, SEEK_SET);     // position in file = offset from start of file
        fwrite(&all_patches[i].new_byte, 1, 1, file);     // change cnt_bytes = 1, cnt_times = 1
    }

    if (fclose(file) == EOF) {
        perror("Error is: can't close file");
        return CLOSE_ERROR;
    }

    return SUCCES;
}


long GetFileSize(const char* filename) {
    assert(filename);

    FILE* file = fopen(filename, "rb");
    if (file == NULL) 
        return -1;
    
    fseek(file, 0, SEEK_END);        
    long size = ftell(file);          

    if (fclose(file) == EOF) {
        perror("Error is: can't close file");
        return -1;
    }
    
    return size;
}


unsigned long Hash(const char* filename) {
    assert(filename);

    FILE* file = fopen(filename, "rb");
    if (file == NULL) 
        return 0;
    
    unsigned long hash = 5381;
    int byte = 0;
    
    while ((byte = fgetc(file)) != EOF)
        hash = ((hash << 5) + hash) ^ byte; 
    
    if (fclose(file) == EOF) {
        perror("Error is: can't close file");
        return 0;
    }

    return hash;
}


int main(int argc, char** argv) {
    const char* patch_file = PATCH_FILE;
    if (argc > 1)
        patch_file = argv[1];

    
    One_patch all_patches[] = {
        {0x07, 0xE9},       // change call to jmp
        {0x08, 0x05},       // new offset of low byte
        {0x09, 0x00}        // new offset of high byte
    };
    int patch_count = sizeof(all_patches) / sizeof(all_patches[0]);


    sf::Texture tex;
    if (tex.loadFromFile("patch/image.png") == 0) 
        return 1;
    sf::RenderWindow window(sf::VideoMode(tex.getSize().x, tex.getSize().y), "My patch");
    sf::Sprite background(tex);

    sf::Texture texWin;
    if (texWin.loadFromFile("patch/image_win.png") == 0) 
        return 1;

    sf::Font font;
    if (font.loadFromFile("patch/font.ttf") == 0)
        return 1;

    sf::Text text;
    text.setFont(font);
    text.setString("Press Enter to Hack\n\nPress Esc to Exit");
    text.setCharacterSize(33);         
    text.setFillColor(sf::Color(128, 0, 128));
    text.setPosition(10.f, 10.f); 

    sf::Music music;
    if (music.openFromFile("patch/music.ogg") == 0) 
        return 1;
    music.setLoop(true);
    music.play();

    while (window.isOpen()) {
        sf::Event event;
        while (window.pollEvent(event)) {
            if (event.type == sf::Event::Closed)
                window.close();

            if (event.type == sf::Event::KeyPressed) {
                if (event.key.code == sf::Keyboard::Escape)
                    window.close();

                if (event.key.code == sf::Keyboard::Enter) {
                    Status status = Patch(patch_file, all_patches, patch_count);
                    if (status == SUCCES) {
                        printf("File patched successfully!\n");
                        text.setString("DONEEEEE!\nPress Esc to Exit");
                        text.setFillColor(sf::Color::Green);

                        background.setTexture(texWin);
                    }   
                    else if (status == ALREADY_PATCHED) {
                        printf("File is already patched\n");
                        text.setString("File is already patched\nPress Esc to Exit");
                        text.setFillColor(sf::Color::Cyan);
                    } 
                    else {
                        printf("Error: patch failed\n");
                        text.setString("Patch failed...\nPress Esc and try again");
                        text.setFillColor(sf::Color::Red);
                    }    
                }
            }
        }

        window.clear();
        window.draw(background);
        window.draw(text);
        window.display();
    }

    return 0;
}