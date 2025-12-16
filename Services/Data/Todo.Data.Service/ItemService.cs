using System;
using System.Collections.Generic;
using System.Text;
using AutoMapper;
using Microsoft.EntityFrameworkCore;
using Todo.Data.Access;
using C = Todo.Data.Entity.Context;
using E = Todo.Data.Entity;

namespace Todo.Data.Service;

// Filtering by Clipboard ID is a good idea if this were a production level app
public class ItemService(IMapper mapper)
{
    public async Task<IList<Item>> GetItems(C context, int clipboardId)
    {
        return await context.Items
            .Where(i => i.ClipboardID == clipboardId)
            .Select(i => mapper.Map<Item>(i))
            .ToListAsync();
    }

    public async Task<Item?> AddItem(C context, int clipboardId, string name)
    {
        if (name.Trim().Length == 0 || await context.Items.AnyAsync(i => i.ClipboardID == clipboardId && i.Name == name))
        {
            return null;
        }

        var entity = new E.Item { ClipboardID = clipboardId, Name = name };
        await context.Items.AddAsync(entity);
        await context.SaveChangesAsync();

        var addedEntity = await context.Items
            .AsNoTracking()
            .SingleAsync(i => i.Name == name);

        return mapper.Map<Item>(addedEntity);
    }

    public async Task<bool> DeleteItem(C context, int id)
    {
        var entity = await context.Items.FindAsync(id);
        if (entity == null)
        {
            return false;
        }
        context.Items.Remove(entity);
        await context.SaveChangesAsync();
        return true;
    }

    public async Task<bool> CompleteItem(C context, int id)
    {
        var entity = await context.Items.FindAsync(id);
        if (entity == null)
        {
            return false;
        }
        entity.IsComplete = true;
        await context.SaveChangesAsync();
        return true;
    }

    public async Task<bool> UnfinishItem(C context, int id)
    {
        var entity = await context.Items.FindAsync(id);
        if (entity == null)
        {
            return false;
        }
        entity.IsComplete = false;
        await context.SaveChangesAsync();
        return true;
    }

    public async Task<bool> EditItem(C context, int id, string name)
    {
        if (name.Trim().Length == 0 || await context.Items.AnyAsync(i => i.Name == name))
        {
            return false;
        }

        var entity = await context.Items.FindAsync(id);
        if (entity == null)
        {
            return false;
        }
        entity.Name = name;
        await context.SaveChangesAsync();
        return true;
    }
}
